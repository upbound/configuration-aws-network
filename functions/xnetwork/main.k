import models.io.upbound.awsm.ec2.v1beta1 as mec2v1beta1
import models.io.upbound.platform.aws.v1alpha1 as platformawsv1alpha1

import regex

oxr = platformawsv1alpha1.XNetwork{**option("params").oxr}
_ocds = option("params").ocds
_dxr = option("params").dxr
dcds = option("params").dcds

params = oxr.spec.parameters    # extract parameter values from XR

_metadata = lambda name = str -> any {
    {
        annotations = {"krm.kcl.dev/composition-resource-name" = name}
    }
}

_cidrEscaped = lambda cidr = str -> str {
    regex.replace(cidr, "\.|\/", "-")
}

_formatSubnet = lambda s = dict -> str {
    "{}-{}-{}".format(s.availabilityZone, _cidrEscaped(s.cidrBlock), s.type)
}

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
            for s in params.subnets
        ]
    ] if createdSubnet.id != None
]

_items = [
    mec2v1beta1.VPC {
        metadata = _metadata("vpc") | {
            labels = {
                "networks.aws.platform.upbound.io/network-id" = params.id
            }
        }
        spec = {
            forProvider = {
                cidrBlock = params.vpcCidrBlock
                enableDnsHostnames = True
                enableDnsSupport = True
                tags = {
                    Name = oxr.metadata.name
                }
                region = params.region
            }
        }
    }

    mec2v1beta1.InternetGateway {
        metadata = _metadata("igw") | {
            labels = {
                "networks.aws.platform.upbound.io/network-id" = params.id
            }
        }
        spec = {
            forProvider = {
                vpcIdSelector = {
                    matchControllerRef = True
                }
                region = params.region
            }
        }
    }
] + [
    mec2v1beta1.Subnet {
        metadata = _metadata("subnet-" + _formatSubnet(s)) | {
            labels = {
                zone = s.availabilityZone
                if s.type == "private":
                    access = "private"
                else:
                    access = "public"
                "networks.aws.platform.upbound.io/network-id" = params.id
            }
        }
        spec = {
            forProvider = {
                cidrBlock = s.cidrBlock
                if s.type == "public":
                    mapPublicIpOnLaunch = True
                tags = {
                    if s.type == "private":
                        "kubernetes.io/role/internal-elb" = "1"
                    else:
                        "kubernetes.io/role/elb" = "1"
                        "networks.aws.platform.upbound.io/network-id" = params.id
                }
                region = params.region
                vpcIdSelector = {
                    matchControllerRef = True
                }
                availabilityZone = s.availabilityZone
            }
        }
    } for s in params.subnets
] + [
    mec2v1beta1.RouteTableAssociation {
        metadata = _metadata("rta-" + _formatSubnet(s)) | {
            labels = {
                "networks.aws.platform.upbound.io/network-id" = params.id
            }
        }
        spec = {
            forProvider = {
                region = params.region
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
    } for s in params.subnets
] + [
    mec2v1beta1.RouteTable {
        metadata = _metadata("rt") | {
            labels = {
                "networks.aws.platform.upbound.io/network-id" = params.id
            }
        }
        spec = {
            forProvider = {
                vpcIdSelector = {
                    matchControllerRef = True
                }
                region = params.region
            }
        }
    }
] + [
    mec2v1beta1.Route {
        metadata = _metadata("route") | {
            labels = {
                "networks.aws.platform.upbound.io/network-id" = params.id
            }
        }
        spec = {
            forProvider = {
                destinationCidrBlock = "0.0.0.0/0"
                gatewayIdSelector = {
                    matchControllerRef = True
                }
                routeTableIdSelector = {
                    matchControllerRef = True
                }
                region = params.region
            }
        }
    }
] + [
    mec2v1beta1.MainRouteTableAssociation {
        metadata = _metadata("mrt") | {
            labels = {
                "networks.aws.platform.upbound.io/network-id" = params.id
            }
        }
        spec = {
            forProvider = {
                routeTableIdSelector = {
                    matchControllerRef = True
                }
                vpcIdSelector = {
                    matchControllerRef = True
                }
                region = params.region
            }
        }
    }
] + [
    mec2v1beta1.SecurityGroup {
        metadata = _metadata("sg") | {
            labels = {
                "networks.aws.platform.upbound.io/network-id" = params.id
            }
        }
        spec = {
            forProvider = {
                description = "Allow access to databases"
                name = "platform-ref-aws-cluster"
                vpcIdSelector = {
                    matchControllerRef = True
                }
                region = params.region
            }
        }
   }
] + [
    mec2v1beta1.SecurityGroupRule {
        metadata = _metadata("sgr-postgres") | {
            labels = {
                "networks.aws.platform.upbound.io/network-id" = params.id
            }
        }
        spec = {
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
                region = params.region
            }
        }
    }
] + [
    mec2v1beta1.SecurityGroupRule {
        metadata = _metadata("sgr-mysql") | {
            labels = {
                "networks.aws.platform.upbound.io/network-id" = params.id
            }
        }
        spec = {
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
                region = params.region
            }
        }
    }
] + [
    platformawsv1alpha1.XNetwork {
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
                id = params.id
                region = params.region
            }
        }
    }
]

items = _items

