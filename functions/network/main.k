import models.io.upbound.awsm.ec2.v1beta2 as ec2v1beta2
import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.platform.aws.v1alpha1 as platformawsv1alpha1

import regex

_oxrRaw = option("params").oxr

# spec.crossplane is Crossplane-owned machinery this function never reads, and the
# renderer writes resourceRefs[].namespace, which the XRD-derived model omits.
oxr = platformawsv1alpha1.Network{
    **_oxrRaw
    spec = {k: v for k, v in _oxrRaw.spec if k != "crossplane"}
}
_ocds = option("params").ocds
_dxr = option("params").dxr
dcds = option("params").dcds

providerConfigRefName = oxr.spec.parameters.providerConfigName or None

_externalNames = oxr.spec.parameters.externalNames or {}

# Every composed resource routes its annotations through here, so injecting the
# external-name at this single point covers all of them - including the
# associations and rules that carry no AWS tags and can only be adopted by an
# identifier the caller supplies.
_metadata = lambda name = str -> any {
    {
        annotations = {
            "krm.kcl.dev/composition-resource-name" = name
            if name in _externalNames:
                "crossplane.io/external-name" = _externalNames[name]
        }
    }
}

# Identity tags. AWS assigns most of this configuration's resource identifiers,
# so a Crossplane control plane holding no prior state cannot find them again by
# name. These two tags are the only stable key: `ctp-id` says which Network the
# resource belongs to, `ctp-resource` says which composed resource it is. A
# consumer discovers them with the Resource Groups Tagging API and feeds the
# result back through `externalNames` to adopt rather than duplicate.
#
# Note provider-upjet-aws already adds a `crossplane-name` tag, but its value is
# the randomly generated managed-resource name, so it cannot serve this purpose.
_identityTags = lambda name = str -> any {
    {
        "upbound.io/ctp-id" = oxr.spec.parameters.id
        "upbound.io/ctp-resource" = name
    }
}

_defaults = {
    managementPolicies = option("params")?.oxr?.spec.parameters.managementPolicies or ["*"]
    if providerConfigRefName:
        providerConfigRef = {
            kind = "ProviderConfig"
            name = providerConfigRefName
        }
}

_cidrEscaped = lambda cidr = str -> str {
    regex.replace(cidr, "\.|\/", "-")
}

_formatSubnet = lambda s = dict -> str {
    "{}-{}-{}".format(s.availabilityZone, _cidrEscaped(s.cidrBlock), s.type)
}

# Every composition-resource-name this function can emit. The subnet and
# route-table-association names are derived from spec.parameters.subnets, so the
# valid set depends on the caller and cannot be enumerated in the XRD schema -
# which is why externalNames is an open map and is validated here instead.
_subnetKeys = ["subnet-" + _formatSubnet(s) for s in oxr.spec.parameters.subnets or []]
_rtaKeys = ["rta-" + _formatSubnet(s) for s in oxr.spec.parameters.subnets or []]
_externalNameKeys = ["vpc", "igw", "rt", "route", "sg", "sgr-postgres", "sgr-mysql"] + _subnetKeys + _rtaKeys

# Fail loudly on an unknown key. Silently ignoring one would leave that resource
# unadopted and create a duplicate in AWS, the exact failure adoption prevents.
_unknownExternalNames = [k for k in _externalNames if k not in _externalNameKeys]

assert len(_unknownExternalNames) == 0, "spec.parameters.externalNames has unknown key(s) ${_unknownExternalNames}; valid keys for this Network are ${_externalNameKeys}"

_getExternalName = lambda resourceName = str -> str {
    id = option("params")?.ocds?[resourceName]?.Resource?.metadata?.annotations?["crossplane.io/external-name"] or None
}

vpcId = option("params")?.ocds?.vpc?.Resource?.status?.atProvider?.id or False
securityGroupId: str = option("params")?.ocds?["sg"]?.Resource?.status?.atProvider?.id or ""

createdSubnets = [
    createdSubnet
    for createdSubnet in [
        {
            id = _getExternalName(subnetResource.name)
            type = subnetResource.type
        }
        for subnetResource in [
            {
                name = "subnet-" + _formatSubnet(s)
                type = s.type
            }
            for s in oxr.spec.parameters.subnets
        ]
    ] if createdSubnet.id != None
]

_items = [
    ec2v1beta1.VPC{
        metadata = _metadata("vpc") | {
            labels = {
                "networks.aws.platform.upbound.io/network-id" = oxr.spec.parameters.id
            }
        }
        spec = _defaults | {
            forProvider = {
                cidrBlock = oxr.spec.parameters.vpcCidrBlock
                enableDnsHostnames = True
                enableDnsSupport = True
                tags = _identityTags("vpc") | {
                    Name = oxr.metadata.name
                }
                region = oxr.spec.parameters.region
            }
        }
    }

    ec2v1beta1.InternetGateway{
        metadata = _metadata("igw") | {
            labels = {
                "networks.aws.platform.upbound.io/network-id" = oxr.spec.parameters.id
            }
        }
        spec = _defaults | {
            forProvider = {
                vpcIdSelector = {
                    matchControllerRef = True
                }
                tags = _identityTags("igw")
                region = oxr.spec.parameters.region
            }
        }
    }
] + [
    ec2v1beta1.Subnet{
        metadata = _metadata("subnet-" + _formatSubnet(s)) | {
            labels = {
                zone = s.availabilityZone
                if s.type == "private":
                    access = "private"
                else:
                    access = "public"
                "networks.aws.platform.upbound.io/network-id" = oxr.spec.parameters.id
            }
        }
        spec = _defaults | {
            forProvider = {
                cidrBlock = s.cidrBlock
                if s.type == "public":
                    mapPublicIpOnLaunch = True
                tags = _identityTags("subnet-" + _formatSubnet(s)) | {
                    if s.type == "private":
                        "kubernetes.io/role/internal-elb" = "1"
                    else:
                        "kubernetes.io/role/elb" = "1"
                        "networks.aws.platform.upbound.io/network-id" = oxr.spec.parameters.id
                }
                region = oxr.spec.parameters.region
                vpcIdSelector = {
                    matchControllerRef = True
                }
                availabilityZone = s.availabilityZone
            }
        }
    } for s in oxr.spec.parameters.subnets
] + [
    ec2v1beta1.RouteTableAssociation{
        metadata = _metadata("rta-" + _formatSubnet(s)) | {
            labels = {
                "networks.aws.platform.upbound.io/network-id" = oxr.spec.parameters.id
            }
        }
        spec = _defaults | {
            forProvider = {
                region = oxr.spec.parameters.region
                routeTableIdSelector = {
                    matchControllerRef = True
                }
                subnetIdSelector = {
                    matchControllerRef = True
                    matchLabels = {
                        if s.type == "private":
                            access = "private"
                        else:
                            access = "public"
                        zone = s.availabilityZone
                    }
                }
            }
        }
    } for s in oxr.spec.parameters.subnets
] + [
    ec2v1beta1.RouteTable{
        metadata = _metadata("rt") | {
            labels = {
                "networks.aws.platform.upbound.io/network-id" = oxr.spec.parameters.id
            }
        }
        spec = _defaults | {
            forProvider = {
                vpcIdSelector = {
                    matchControllerRef = True
                }
                tags = _identityTags("rt")
                region = oxr.spec.parameters.region
            }
        }
    }
] + [
    ec2v1beta1.Route{
        metadata = _metadata("route") | {
            labels = {
                "networks.aws.platform.upbound.io/network-id" = oxr.spec.parameters.id
            }
        }
        spec = _defaults | {
            forProvider = {
                destinationCidrBlock = "0.0.0.0/0"
                gatewayIdSelector = {
                    matchControllerRef = True
                }
                routeTableIdSelector = {
                    matchControllerRef = True
                }
                region = oxr.spec.parameters.region
            }
        }
    }
] + [
    # No MainRouteTableAssociation: it added no routing (every subnet above is
    # associated explicitly) and on re-apply left `rt` as the VPC's main table,
    # which AWS refuses to disassociate - leaking `rt` and the VPC.
    ec2v1beta1.SecurityGroup{
        metadata = _metadata("sg") | {
            labels = {
                "networks.aws.platform.upbound.io/network-id" = oxr.spec.parameters.id
            }
        }
        spec = _defaults | {
            forProvider = {
                description = "Allow access to databases"
                name = "platform-ref-aws-cluster"
                vpcIdSelector = {
                    matchControllerRef = True
                }
                tags = _identityTags("sg")
                region = oxr.spec.parameters.region
            }
        }
   }
] + [
    ec2v1beta1.SecurityGroupRule{
        metadata = _metadata("sgr-postgres") | {
            labels = {
                "networks.aws.platform.upbound.io/network-id" = oxr.spec.parameters.id
            }
        }
        spec = _defaults | {
            forProvider = {
                cidrBlocks = [
                    "0.0.0.0/0"
                ]
                description = "Everywhere"
                fromPort = 5432
                protocol = "tcp"
                securityGroupIdSelector = {
                    matchControllerRef = True
                }
                toPort = 5432
                type = "ingress"
                region = oxr.spec.parameters.region
            }
        }
    }
] + [
    ec2v1beta1.SecurityGroupRule{
        metadata = _metadata("sgr-mysql") | {
            labels = {
                "networks.aws.platform.upbound.io/network-id" = oxr.spec.parameters.id
            }
        }
        spec = _defaults | {
            forProvider = {
                cidrBlocks = [
                    "0.0.0.0/0"
                ]
                description = "Everywhere"
                fromPort = 3306
                protocol = "tcp"
                securityGroupIdSelector = {
                    matchControllerRef = True
                }
                toPort = 3306
                type = "ingress"
                region = oxr.spec.parameters.region
            }
        }
    }
] + [
    platformawsv1alpha1.Network{
        status = {
            if vpcId:
                vpcId = vpcId
            subnetIds = [s.id for s in createdSubnets]
            publicSubnetIds = [s.id for s in createdSubnets if s.type == "public"]
            privateSubnetIds = [s.id for s in createdSubnets if s.type == "private"]
            securityGroupIds = [securityGroupId]
        }
        spec = {
            parameters = {
                id = oxr.spec.parameters.id
                region = oxr.spec.parameters.region
            }
        }
    }
]

items = _items

