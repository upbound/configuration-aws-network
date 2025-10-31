import models.io.upbound.awsm.ec2.v1beta1 as mec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.aws.v1alpha1 as platformawsv1alpha1

# It's a best practice for composition functions to return only fields whose
# values they care about, since they become the owner of any field they
# return. Allow for fields with defaults to be omitted by the composition
# function by clearing them in our expected resources.
_stripDefaults = lambda obj: any -> any {
    obj | {
        spec.managementPolicies = Undefined
    }
}

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-xnetwork"
        spec= {
            assertResources: [
                platformawsv1alpha1.XNetwork{
                    metadata = {
                        name = "configuration-aws-network"
                    }
                    spec.parameters = {
                        id = "configuration-aws-network"
                        region = "us-west-2"
                    }
                }
                _stripDefaults(mec2v1beta1.SecurityGroup {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "sg"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                        }
                        ownerReferences = [
                            {
                                apiVersion = "aws.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "XNetwork"
                                name = "configuration-aws-network"
                                uid = ""
                            }
                        ]
                    }
                    spec = {
                        forProvider = {
                            description = "Allow access to databases"
                            name = "platform-ref-aws-cluster"
                            region = "us-west-2"
                            vpcIdSelector = {
                                matchControllerRef = True
                            }
                        }
                        managementPolicies = [
                            "*"
                        ]
                    }
                })
                _stripDefaults(mec2v1beta1.SecurityGroupRule {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "sgr-mysql"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                        }
                        ownerReferences = [
                            {
                                apiVersion = "aws.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "XNetwork"
                                name = "configuration-aws-network"
                                uid = ""
                            }
                        ]
                    }
                    spec = {
                        forProvider = {
                            cidrBlocks = [
                                "0.0.0.0/0"
                            ]
                            description = "Everywhere"
                            fromPort = 3306
                            $protocol = "tcp"
                            region = "us-west-2"
                            securityGroupIdSelector = {
                                matchControllerRef = True
                            }
                            toPort = 3306
                            $type = "ingress"
                        }
                        managementPolicies = [
                            "*"
                        ]
                    }
                })
                _stripDefaults(mec2v1beta1.SecurityGroupRule {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "sgr-postgres"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                        }
                        ownerReferences = [
                            {
                                apiVersion = "aws.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "XNetwork"
                                name = "configuration-aws-network"
                                uid = ""
                            }
                        ]
                    }
                    spec = {
                        forProvider = {
                            cidrBlocks = [
                                "0.0.0.0/0"
                            ]
                            description = "Everywhere"
                            fromPort = 5432
                            $protocol = "tcp"
                            region = "us-west-2"
                            securityGroupIdSelector = {
                                matchControllerRef = True
                            }
                            toPort = 5432
                            $type = "ingress"
                        }
                        managementPolicies = [
                            "*"
                        ]
                    }
                })
                _stripDefaults(mec2v1beta1.Subnet {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "subnet-us-west-2a-192-168-0-0-18-public"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            access = "public"
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                            zone = "us-west-2a"
                        }
                        ownerReferences = [
                            {
                                apiVersion = "aws.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "XNetwork"
                                name = "configuration-aws-network"
                                uid = ""
                            }
                        ]
                    }
                    spec = {
                        forProvider = {
                            availabilityZone = "us-west-2a"
                            cidrBlock = "192.168.0.0/18"
                            mapPublicIpOnLaunch = True
                            region = "us-west-2"
                            tags = {
                                "kubernetes.io/role/elb" = "1"
                                "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                            }
                            vpcIdSelector = {
                                matchControllerRef = True
                            }
                        }
                        managementPolicies = [
                            "*"
                        ]
                    }
                })
                _stripDefaults(mec2v1beta1.Subnet {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "subnet-us-west-2a-192-168-128-0-18-private"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            access = "private"
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                            zone = "us-west-2a"
                        }
                        ownerReferences = [
                            {
                                apiVersion = "aws.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "XNetwork"
                                name = "configuration-aws-network"
                                uid = ""
                            }
                        ]
                    }
                    spec = {
                        forProvider = {
                            availabilityZone = "us-west-2a"
                            cidrBlock = "192.168.128.0/18"
                            region = "us-west-2"
                            tags = {
                                "kubernetes.io/role/internal-elb" = "1"
                            }
                            vpcIdSelector = {
                                matchControllerRef = True
                            }
                        }
                        managementPolicies = [
                            "*"
                        ]
                    }
                })
                _stripDefaults(mec2v1beta1.Subnet {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "subnet-us-west-2b-192-168-192-0-18-private"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            access = "private"
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                            zone = "us-west-2b"
                        }
                        ownerReferences = [
                            {
                                apiVersion = "aws.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "XNetwork"
                                name = "configuration-aws-network"
                                uid = ""
                            }
                        ]
                    }
                    spec = {
                        forProvider = {
                            availabilityZone = "us-west-2b"
                            cidrBlock = "192.168.192.0/18"
                            region = "us-west-2"
                            tags = {
                                "kubernetes.io/role/internal-elb" = "1"
                            }
                            vpcIdSelector = {
                                matchControllerRef = True
                            }
                        }
                        managementPolicies = [
                            "*"
                        ]
                    }
                })
                _stripDefaults(mec2v1beta1.Subnet {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "subnet-us-west-2b-192-168-64-0-18-public"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            access = "public"
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                            zone = "us-west-2b"
                        }
                        ownerReferences = [
                            {
                                apiVersion = "aws.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "XNetwork"
                                name = "configuration-aws-network"
                                uid = ""
                            }
                        ]
                    }
                    spec = {
                        forProvider = {
                            availabilityZone = "us-west-2b"
                            cidrBlock = "192.168.64.0/18"
                            mapPublicIpOnLaunch = True
                            region = "us-west-2"
                            tags = {
                                "kubernetes.io/role/elb" = "1"
                                "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                            }
                            vpcIdSelector = {
                                matchControllerRef = True
                            }
                        }
                        managementPolicies = [
                            "*"
                        ]
                    }
                })
                _stripDefaults(mec2v1beta1.VPC {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "vpc"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                        }
                        ownerReferences = [
                            {
                                apiVersion = "aws.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "XNetwork"
                                name = "configuration-aws-network"
                                uid = ""
                            }
                        ]
                    }
                    spec = {
                        forProvider = {
                            cidrBlock = "192.168.0.0/16"
                            enableDnsHostnames = True
                            enableDnsSupport = True
                            region = "us-west-2"
                            tags = {
                                Name = "configuration-aws-network"
                            }
                        }
                        managementPolicies = [
                            "*"
                        ]
                    }
                })
                _stripDefaults(mec2v1beta1.InternetGateway {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "igw"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                        }
                        ownerReferences = [
                            {
                                apiVersion = "aws.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "XNetwork"
                                name = "configuration-aws-network"
                                uid = ""
                            }
                        ]
                    }
                    spec = {
                        forProvider = {
                            region = "us-west-2"
                            vpcIdSelector = {
                                matchControllerRef = True
                            }
                        }
                        managementPolicies = [
                            "*"
                        ]
                    }
                })
                _stripDefaults(mec2v1beta1.MainRouteTableAssociation {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "mrt"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                        }
                        ownerReferences = [
                            {
                                apiVersion = "aws.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "XNetwork"
                                name = "configuration-aws-network"
                                uid = ""
                            }
                        ]
                    }
                    spec = {
                        forProvider = {
                            region = "us-west-2"
                            routeTableIdSelector = {
                                matchControllerRef = True
                            }
                            vpcIdSelector = {
                                matchControllerRef = True
                            }
                        }
                        managementPolicies = [
                            "*"
                        ]
                    }
                })
                _stripDefaults(mec2v1beta1.Route {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "route"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                        }
                        ownerReferences = [
                            {
                                apiVersion = "aws.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "XNetwork"
                                name = "configuration-aws-network"
                                uid = ""
                            }
                        ]
                    }
                    spec = {
                        forProvider = {
                            destinationCidrBlock = "0.0.0.0/0"
                            gatewayIdSelector = {
                                matchControllerRef = True
                            }
                            region = "us-west-2"
                            routeTableIdSelector = {
                                matchControllerRef = True
                            }
                        }
                        managementPolicies = [
                            "*"
                        ]
                    }
                })
                _stripDefaults(mec2v1beta1.RouteTable {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "rt"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                        }
                        ownerReferences = [
                            {
                                apiVersion = "aws.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "XNetwork"
                                name = "configuration-aws-network"
                                uid = ""
                            }
                        ]
                    }
                    spec = {
                        forProvider = {
                            region = "us-west-2"
                            vpcIdSelector = {
                                matchControllerRef = True
                            }
                        }
                        managementPolicies = [
                            "*"
                        ]
                    }
                })
                _stripDefaults(mec2v1beta1.RouteTableAssociation {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "rta-us-west-2a-192-168-0-0-18-public"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                        }
                        ownerReferences = [
                            {
                                apiVersion = "aws.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "XNetwork"
                                name = "configuration-aws-network"
                                uid = ""
                            }
                        ]
                    }
                    spec = {
                        forProvider = {
                            region = "us-west-2"
                            routeTableIdSelector = {
                                matchControllerRef = True
                            }
                            subnetIdSelector = {
                                matchControllerRef = True
                                matchLabels = {
                                    access = "public"
                                    zone = "us-west-2a"
                                }
                            }
                        }
                        managementPolicies = [
                            "*"
                        ]
                    }
                })
                _stripDefaults(mec2v1beta1.RouteTableAssociation {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "rta-us-west-2a-192-168-128-0-18-private"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                        }
                        ownerReferences = [
                            {
                                apiVersion = "aws.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "XNetwork"
                                name = "configuration-aws-network"
                                uid = ""
                            }
                        ]
                    }
                    spec = {
                        forProvider = {
                            region = "us-west-2"
                            routeTableIdSelector = {
                                matchControllerRef = True
                            }
                            subnetIdSelector = {
                                matchControllerRef = True
                                matchLabels = {
                                    access = "private"
                                    zone = "us-west-2a"
                                }
                            }
                        }
                        managementPolicies = [
                            "*"
                        ]
                    }
                })
                _stripDefaults(mec2v1beta1.RouteTableAssociation {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "rta-us-west-2b-192-168-192-0-18-private"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                        }
                        ownerReferences = [
                            {
                                apiVersion = "aws.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "XNetwork"
                                name = "configuration-aws-network"
                                uid = ""
                            }
                        ]
                    }
                    spec = {
                        forProvider = {
                            region = "us-west-2"
                            routeTableIdSelector = {
                                matchControllerRef = True
                            }
                            subnetIdSelector = {
                                matchControllerRef = True
                                matchLabels = {
                                    access = "private"
                                    zone = "us-west-2b"
                                }
                            }
                        }
                        managementPolicies = [
                            "*"
                        ]
                    }
                })
                _stripDefaults(mec2v1beta1.RouteTableAssociation {
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "rta-us-west-2b-192-168-64-0-18-public"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                        }
                        ownerReferences = [
                            {
                                apiVersion = "aws.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "XNetwork"
                                name = "configuration-aws-network"
                                uid = ""
                            }
                        ]
                    }
                    spec = {
                        forProvider = {
                            region = "us-west-2"
                            routeTableIdSelector = {
                                matchControllerRef = True
                            }
                            subnetIdSelector = {
                                matchControllerRef = True
                                matchLabels = {
                                    access = "public"
                                    zone = "us-west-2b"
                                }
                            }
                        }
                        managementPolicies = [
                            "*"
                        ]
                    }
                })
            ]
            compositionPath: "apis/xnetworks/composition.yaml"
            xrPath: "examples/xnetworks/configuration-aws-network.yaml"
            xrdPath: "apis/xnetworks/definition.yaml"
            timeoutSeconds: 60
            validate: False
        }
    }
]
items= _items
