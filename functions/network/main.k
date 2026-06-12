# =============================================================================
# Network composition function — v3 implementation (Layer 3)
# =============================================================================
# The ONLY layer where provider resources and provider field names appear.
#
# Determinism note: resource names and the subnet plan are pure functions of
# spec, so reconciles are stable and brownfield adoption (matching external
# names) is predictable. plan_subnets(192.168.0.0/16, 2, public-private)
# reproduces the legacy layout exactly.
# =============================================================================

import models.io.upbound.awsm.ec2.v1beta2 as ec2v1beta2
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.platform.aws.v1alpha1 as platformawsv1alpha1

import regex

oxr = platformawsv1alpha1.Network{**option("params").oxr}
_ocds = option("params").ocds
_dxr = option("params").dxr
dcds = option("params").dcds
params = oxr.spec.parameters

# -----------------------------------------------------------------------------
# Inputs (XRD defaults guard most of these; `or` fallbacks keep render safe)
# -----------------------------------------------------------------------------
_id = params.id
_region = params.region
_azCount = params.availabilityZones or 3
_cidr = params.cidrBlock or "10.0.0.0/16"
_strategy = params.subnetStrategy or "public-private"
_natMode = params.natGateway or "single"
_secPolicy = params.defaultSecurityPolicy or "restrictive"
_userTags = params.tags or {}
_reclaimPolicy = params.reclaimPolicy or "Delete"
_providerConfigName = params.overrides?.providerConfigName or "default"
_azOverride = params.overrides?.availabilityZoneNames or []

_networkIdTag = "networks.network.platform.upbound.io/network-id"

# reclaimPolicy intent (PV vocabulary) -> Crossplane v2 management policies
# on the namespaced MRs. This mapping is the L3-owned translation: the
# consumer contract speaks Kubernetes; only this line speaks Crossplane.
_managementPolicies = ["Create", "Observe", "Update", "LateInitialize"] if _reclaimPolicy == "Retain" else ["*"]

_defaults = {
    managementPolicies = _managementPolicies
    providerConfigRef = {
        kind = "ProviderConfig"
        name = _providerConfigName
    }
}

_metadata = lambda name: str -> any {
    {
        annotations = {"krm.kcl.dev/composition-resource-name" = name}
        labels = {"{}".format(_networkIdTag) = _id}
    }
}

_baseTags = {"Name" = oxr.metadata.name, "{}".format(_networkIdTag) = _id} | _userTags

# -----------------------------------------------------------------------------
# AZ resolution: derived region suffixes, override escape hatch wins
# -----------------------------------------------------------------------------
_azSuffixes = ["a", "b", "c", "d", "e", "f"]
_azs = _azOverride if len(_azOverride) == _azCount else [
    _region + s for s in _azSuffixes[0:_azCount]
]

# -----------------------------------------------------------------------------
# Subnet plan: pure CIDR math over the parent block
#   two tiers  -> halves of the parent (public low, private high)
#   one tier   -> whole parent
#   each tier  -> split across next-power-of-two >= azCount
# -----------------------------------------------------------------------------
_ipToInt = lambda ip: str -> int {
    _p = [int(x) for x in ip.split(".")]
    _p[0] * 16777216 + _p[1] * 65536 + _p[2] * 256 + _p[3]
}
_intToIp = lambda n: int -> str {
    "{}.{}.{}.{}".format(n // 16777216 % 256, n // 65536 % 256, n // 256 % 256, n % 256)
}

_parentBase = _ipToInt(_cidr.split("/")[0])
_parentPrefix = int(_cidr.split("/")[1])
_azBits = 0 if _azCount <= 1 else 1 if _azCount <= 2 else 2 if _azCount <= 4 else 3
_tiers = ["public", "private"] if _strategy == "public-private" \
    else ["public"] if _strategy == "public-only" else ["private"]
_tierPrefix = _parentPrefix + (1 if len(_tiers) == 2 else 0)
_tierSize = 2 ** (32 - _tierPrefix)
_subPrefix = _tierPrefix + _azBits
_subSize = 2 ** (32 - _subPrefix)

_plan = [
    {
        tier = _tiers[t]
        az = _azs[a]
        cidr = "{}/{}".format(_intToIp(_parentBase + t * _tierSize + a * _subSize), _subPrefix)
        name = "subnet-{}-{}".format(_tiers[t], _azs[a])
    }
    for t in range(len(_tiers)) for a in range(_azCount)
]
_publicPlan = [s for s in _plan if s.tier == "public"]
_privatePlan = [s for s in _plan if s.tier == "private"]

# NAT requires a public tier to live in; degrade to none otherwise
_natCount = 0 if _natMode == "none" or len(_publicPlan) == 0 or len(_privatePlan) == 0 \
    else _azCount if _natMode == "per-az" else 1
_natAzs = _azs[0:_natCount]

# -----------------------------------------------------------------------------
# Observed state -> status inputs
# -----------------------------------------------------------------------------
_getExternalName = lambda resourceName: str -> str {
    _ocds?[resourceName]?.Resource?.metadata?.annotations?["crossplane.io/external-name"] or None
}
_vpcId = _ocds?.vpc?.Resource?.status?.atProvider?.id or False
_sgId: str = _ocds?["sg"]?.Resource?.status?.atProvider?.id or ""
_createdSubnets = [
    s2 for s2 in [
        {id = _getExternalName(s.name), tier = s.tier} for s in _plan
    ] if s2.id != None
]

# =============================================================================
# Resources
# =============================================================================
_vpc = [
    ec2v1beta1.VPC{
        metadata = _metadata("vpc") 
        spec = _defaults | {
            forProvider = {
                cidrBlock = _cidr
                enableDnsSupport = params.dnsSupport if params.dnsSupport != None else True
                enableDnsHostnames = params.dnsHostnames if params.dnsHostnames != None else True
                region = _region
                tags = _baseTags
            }
        }
    }
]

_igw = [
    ec2v1beta1.InternetGateway{
        metadata = _metadata("igw")
        spec = _defaults | {
            forProvider = {
                vpcIdSelector.matchControllerRef = True
                region = _region
                tags = _baseTags
            }
        }
    }
] if len(_publicPlan) > 0 else []

# Subnets: network-id tag on BOTH tiers (fixes B4); ELB role tags per tier
_subnets = [
    ec2v1beta1.Subnet{
        metadata = _metadata(s.name) | {
            labels = {
                zone = s.az
                access = s.tier
                "{}".format(_networkIdTag) = _id
            }
        }
        spec = _defaults | {
            forProvider = {
                cidrBlock = s.cidr
                availabilityZone = s.az
                region = _region
                vpcIdSelector.matchControllerRef = True
                
                if s.tier == "public":
                    mapPublicIpOnLaunch = True
                tags = _baseTags | {
                    if s.tier == "public":
                        "kubernetes.io/role/elb" = "1"
                    else:
                        "kubernetes.io/role/internal-elb" = "1"
                }
            }
        }
    } for s in _plan
]

# NAT egress: one EIP + NATGateway per strategy-determined zone,
# placed in that zone's PUBLIC subnet
_eips = [
    ec2v1beta1.EIP{
        metadata = _metadata("eip-" + az) | {
            labels = {
                "nat-zone" = az, 
                "{}".format(_networkIdTag) = _id
            }
        }
        spec = _defaults | {
            forProvider = {
                domain = "vpc"
                region = _region
                tags = _baseTags
            }
        }
    } for az in _natAzs
]

_nats = [
    ec2v1beta1.NATGateway{
        metadata = _metadata("nat-" + az) | {
            labels = {
                zone = az, "{}".format(_networkIdTag) = _id
            }
        }
        spec = _defaults | {
            forProvider = {
                region = _region
                subnetIdSelector = {
                    matchControllerRef = True
                    matchLabels = {access = "public", zone = az}
                }
                allocationIdSelector = {
                    matchControllerRef = True
                    matchLabels = {"nat-zone" = az}
                }
                tags = _baseTags
            }
        }
    } for az in _natAzs
]

# Route tables (fixes B1):
#   one PUBLIC RT  -> default route to IGW
#   one PRIVATE RT PER AZ -> default route to its NAT (zone-matched for
#   per-az; the single NAT via controllerRef otherwise; no route for none)
_publicRT = [
    ec2v1beta1.RouteTable{
        metadata = _metadata("rt-public") | {
            labels = {
                tier = "public", "{}".format(_networkIdTag) = _id
            }
        }
        spec = _defaults | {
            forProvider = {
                vpcIdSelector.matchControllerRef = True
                region = _region
                tags = _baseTags
            }
        }
    }

    ec2v1beta1.Route{
        metadata = _metadata("route-public-egress")
        spec = _defaults | {
            forProvider = {
                destinationCidrBlock = "0.0.0.0/0"
                gatewayIdSelector.matchControllerRef = True
                routeTableIdSelector = {
                    matchControllerRef = True
                    matchLabels = {tier = "public"}
                }
                region = _region
            }
        }
    }
] if len(_publicPlan) > 0 else []

_privateRTs = [
    ec2v1beta1.RouteTable{
        metadata = _metadata("rt-private-" + s.az) | {
            labels = {
                tier = "private", zone = s.az, 
                "{}".format(_networkIdTag) = _id
            }
        }
        spec = _defaults | {
            forProvider = {
                vpcIdSelector.matchControllerRef = True
                region = _region
                tags = _baseTags
            }
        }
    } for s in _privatePlan
]

_privateRoutes = [
    ec2v1beta1.Route{
        metadata = _metadata("route-private-egress-" + s.az)
        spec = _defaults | {
            forProvider = {
                destinationCidrBlock = "0.0.0.0/0"
                natGatewayIdSelector = {
                    matchControllerRef = True
                    if _natMode == "per-az":
                        matchLabels = {zone = s.az}
                }
                routeTableIdSelector = {
                    matchControllerRef = True
                    matchLabels = {tier = "private", zone = s.az}
                }
                region = _region
            }
        }
    } for s in _privatePlan
] if _natCount > 0 else []

_rtas = [
    ec2v1beta1.RouteTableAssociation{
        metadata = _metadata("rta-" + s.name)
        spec = _defaults | {
            forProvider = {
                region = _region
                routeTableIdSelector = {
                    matchControllerRef = True
                    matchLabels = {
                        tier = "public"
                    } if s.tier == "public" \
                    else {
                        tier = "private", 
                        zone = s.az
                    }
                }
                subnetIdSelector = {
                    matchControllerRef = True
                    matchLabels = {
                        access = s.tier, 
                        zone = s.az
                    }
                }
            }
        }
    } for s in _plan
]

# Security group (fixes B2, B3): named from THIS resource, policy-driven,
# zero service-specific knowledge
_sg = [
    ec2v1beta1.SecurityGroup{
        metadata = _metadata("sg")
        spec = _defaults | {
            forProvider = {
                name = oxr.metadata.name + "-default"
                description = "Default security group for network " + _id
                vpcIdSelector.matchControllerRef = True
                region = _region
                tags = _baseTags
            }
        }
    }
]
_sgRules = [
    ec2v1beta1.SecurityGroupRule{
        metadata = _metadata("sgr-intra-network")
        spec = _defaults | {
            forProvider = {
                type = "ingress"
                protocol = "-1"
                fromPort = 0
                toPort = 0
                cidrBlocks = [_cidr]
                description = "Allow all traffic originating within the network CIDR"
                securityGroupIdSelector.matchControllerRef = True
                region = _region
            }
        }
    }
] if _secPolicy == "permissive" else []

# Status: the stable inter-domain contract (field names outlive providers)
_status = [
    platformawsv1alpha1.Network{
        status = {
            if _vpcId:
                networkId = _vpcId
            subnetIds = [s.id for s in _createdSubnets]
            publicSubnetIds = [s.id for s in _createdSubnets if s.tier == "public"]
            privateSubnetIds = [s.id for s in _createdSubnets if s.tier == "private"]
            securityGroupIds = [_sgId]
            availabilityZoneNames = _azs
            cidrBlock = _cidr
        }
        spec = {
            parameters = {
                id = _id
                region = _region
            }
        }
    }
]

items = _vpc + _igw + _subnets + _eips + _nats + _publicRT + \
    _privateRTs + _privateRoutes + _rtas + _sg + _sgRules + _status
