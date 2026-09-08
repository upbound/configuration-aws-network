import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.awsm.ec2.v1beta2 as ec2v1beta2
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.aws.v1alpha1 as platformawsv1alpha1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-network"
        spec= {
            assertResources: [
                platformawsv1alpha1.Network{
                    metadata = {
                        name = "configuration-aws-network"
                    }
                    spec.parameters = {
                        id = "configuration-aws-network"
                        region = "us-west-2"
                    }
                }
                ec2v1beta1.SecurityGroup{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "sg"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                        }
                    }
                    spec = {
                        forProvider = {
                            description = "Allow access to databases"
                            name = "platform-ref-aws-cluster"
                            region = "us-west-2"
                            tags = {
                                "upbound.io/ctp-id" = "configuration-aws-network"
                                "upbound.io/ctp-resource" = "sg"
                            }
                            vpcIdSelector = {
                                matchControllerRef = True
                            }
                        }
                        managementPolicies = [
                            "*"
                        ]
                        providerConfigRef = {
                            kind = "ProviderConfig"
                            name = "default"
                        }
                    }
                }
                ec2v1beta1.SecurityGroupRule{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "sgr-mysql"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                        }
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
                        providerConfigRef = {
                            kind = "ProviderConfig"
                            name = "default"
                        }
                    }
                }
                ec2v1beta1.SecurityGroupRule{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "sgr-postgres"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                        }
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
                        providerConfigRef = {
                            kind = "ProviderConfig"
                            name = "default"
                        }
                    }
                }
                ec2v1beta1.Subnet{
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
                                "upbound.io/ctp-id" = "configuration-aws-network"
                                "upbound.io/ctp-resource" = "subnet-us-west-2a-192-168-0-0-18-public"
                            }
                            vpcIdSelector = {
                                matchControllerRef = True
                            }
                        }
                        managementPolicies = [
                            "*"
                        ]
                        providerConfigRef = {
                            kind = "ProviderConfig"
                            name = "default"
                        }
                    }
                }
                ec2v1beta1.Subnet{
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
                    }
                    spec = {
                        forProvider = {
                            availabilityZone = "us-west-2a"
                            cidrBlock = "192.168.128.0/18"
                            region = "us-west-2"
                            tags = {
                                "kubernetes.io/role/internal-elb" = "1"
                                "upbound.io/ctp-id" = "configuration-aws-network"
                                "upbound.io/ctp-resource" = "subnet-us-west-2a-192-168-128-0-18-private"
                            }
                            vpcIdSelector = {
                                matchControllerRef = True
                            }
                        }
                        managementPolicies = [
                            "*"
                        ]
                        providerConfigRef = {
                            kind = "ProviderConfig"
                            name = "default"
                        }
                    }
                }
                ec2v1beta1.Subnet{
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
                    }
                    spec = {
                        forProvider = {
                            availabilityZone = "us-west-2b"
                            cidrBlock = "192.168.192.0/18"
                            region = "us-west-2"
                            tags = {
                                "kubernetes.io/role/internal-elb" = "1"
                                "upbound.io/ctp-id" = "configuration-aws-network"
                                "upbound.io/ctp-resource" = "subnet-us-west-2b-192-168-192-0-18-private"
                            }
                            vpcIdSelector = {
                                matchControllerRef = True
                            }
                        }
                        managementPolicies = [
                            "*"
                        ]
                        providerConfigRef = {
                            kind = "ProviderConfig"
                            name = "default"
                        }
                    }
                }
                ec2v1beta1.Subnet{
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
                                "upbound.io/ctp-id" = "configuration-aws-network"
                                "upbound.io/ctp-resource" = "subnet-us-west-2b-192-168-64-0-18-public"
                            }
                            vpcIdSelector = {
                                matchControllerRef = True
                            }
                        }
                        managementPolicies = [
                            "*"
                        ]
                        providerConfigRef = {
                            kind = "ProviderConfig"
                            name = "default"
                        }
                    }
                }
                ec2v1beta1.VPC{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "vpc"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                        }
                    }
                    spec = {
                        forProvider = {
                            cidrBlock = "192.168.0.0/16"
                            enableDnsHostnames = True
                            enableDnsSupport = True
                            region = "us-west-2"
                            tags = {
                                Name = "configuration-aws-network"
                                "upbound.io/ctp-id" = "configuration-aws-network"
                                "upbound.io/ctp-resource" = "vpc"
                            }
                        }
                        managementPolicies = [
                            "*"
                        ]
                        providerConfigRef = {
                            kind = "ProviderConfig"
                            name = "default"
                        }
                    }
                }
                ec2v1beta1.InternetGateway{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "igw"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                        }
                    }
                    spec = {
                        forProvider = {
                            region = "us-west-2"
                            tags = {
                                "upbound.io/ctp-id" = "configuration-aws-network"
                                "upbound.io/ctp-resource" = "igw"
                            }
                            vpcIdSelector = {
                                matchControllerRef = True
                            }
                        }
                        managementPolicies = [
                            "*"
                        ]
                        providerConfigRef = {
                            kind = "ProviderConfig"
                            name = "default"
                        }
                    }
                }
                ec2v1beta1.Route{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "route"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                        }
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
                        providerConfigRef = {
                            kind = "ProviderConfig"
                            name = "default"
                        }
                    }
                }
                ec2v1beta1.RouteTable{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "rt"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                        }
                    }
                    spec = {
                        forProvider = {
                            region = "us-west-2"
                            tags = {
                                "upbound.io/ctp-id" = "configuration-aws-network"
                                "upbound.io/ctp-resource" = "rt"
                            }
                            vpcIdSelector = {
                                matchControllerRef = True
                            }
                        }
                        managementPolicies = [
                            "*"
                        ]
                        providerConfigRef = {
                            kind = "ProviderConfig"
                            name = "default"
                        }
                    }
                }
                ec2v1beta1.RouteTableAssociation{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "rta-us-west-2a-192-168-0-0-18-public"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                        }
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
                        providerConfigRef = {
                            kind = "ProviderConfig"
                            name = "default"
                        }
                    }
                }
                ec2v1beta1.RouteTableAssociation{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "rta-us-west-2a-192-168-128-0-18-private"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                        }
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
                        providerConfigRef = {
                            kind = "ProviderConfig"
                            name = "default"
                        }
                    }
                }
                ec2v1beta1.RouteTableAssociation{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "rta-us-west-2b-192-168-192-0-18-private"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                        }
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
                        providerConfigRef = {
                            kind = "ProviderConfig"
                            name = "default"
                        }
                    }
                }
                ec2v1beta1.RouteTableAssociation{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "rta-us-west-2b-192-168-64-0-18-public"
                        }
                        generateName = "configuration-aws-network-"
                        labels = {
                            "crossplane.io/composite" = "configuration-aws-network"
                            "networks.aws.platform.upbound.io/network-id" = "configuration-aws-network"
                        }
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
                        providerConfigRef = {
                            kind = "ProviderConfig"
                            name = "default"
                        }
                    }
                }
            ]
            compositionPath: "apis/networks/composition.yaml"
            xrPath: "examples/networks/configuration-aws-network.yaml"
            xrdPath: "apis/networks/definition.yaml"
            timeoutSeconds: 60
            validate: False
        }
    }
    metav1alpha1.CompositionTest{
        metadata.name: "test-network-external-names"
        spec= {
            # An injected external-name makes Crossplane observe the existing AWS
            # object instead of creating a duplicate. AWS assigns VPC and subnet
            # ids, so a control plane with no prior state has no other way to
            # adopt them. Unlisted resources are unaffected.
            xr: platformawsv1alpha1.Network{
                metadata = {
                    name = "configuration-aws-network"
                    namespace = "network-team"
                }
                spec.parameters = {
                    id = "configuration-aws-network"
                    region = "us-west-2"
                    externalNames = {
                        vpc = "vpc-08a368fd767569aed"
                        igw = "igw-086295b0369e2ab86"
                    }
                }
            }
            assertResources: [
                ec2v1beta1.VPC{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "vpc"
                            "crossplane.io/external-name" = "vpc-08a368fd767569aed"
                        }
                    }
                    spec.forProvider.region = "us-west-2"
                }
                ec2v1beta1.InternetGateway{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "igw"
                            "crossplane.io/external-name" = "igw-086295b0369e2ab86"
                        }
                    }
                    spec.forProvider.region = "us-west-2"
                }
            ]
            compositionPath: "apis/networks/composition.yaml"
            xrdPath: "apis/networks/definition.yaml"
            timeoutSeconds: 60
            validate: False
        }
    }
]
items= _items
