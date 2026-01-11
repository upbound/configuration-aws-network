import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.aws.v1alpha1 as platformawsv1alpha1


_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-xnetwork"
        spec= {
            assertResources: [
                platformawsv1alpha1.Network{
                    metadata = {
                        name = "configuration-aws-network"
                        namespace = "default"
                    }
                    spec.parameters = {
                        id = "configuration-aws-network"
                        region = "us-west-2"
                    }
                    status: {
                        securityGroupIds: [
                            "sg-0be55443dc4247834"
                        ]
                        privateSubnetIds: [
                            "subnet-01df6730262d519b4"
                            "subnet-0260ebe3484994e2b"
                        ]
                        publicSubnetIds: [
                            "subnet-0775f953a8271ef84"
                            "subnet-07a115654ea808b78"
                        ]
                        subnetIds: [
                            "subnet-0775f953a8271ef84"
                            "subnet-07a115654ea808b78"
                            "subnet-01df6730262d519b4"
                            "subnet-0260ebe3484994e2b"
                        ]
                        vpcId: "vpc-091a39902df7a340a"
                    }
                }
            ]
            observedResources: [
                ec2v1beta1.SecurityGroup{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "sg"
                            "crossplane.io/external-name": "sg-0be55443dc4247834"
                        }
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
                    status: {
                        atProvider: {
                            id: "sg-0be55443dc4247834"
                        }
                    }
                }
                ec2v1beta1.Subnet{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "subnet-us-west-2a-192-168-0-0-18-public"
                            "crossplane.io/external-name" = "subnet-0775f953a8271ef84"
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
                                kind = "Network"
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
                }
                ec2v1beta1.Subnet{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "subnet-us-west-2a-192-168-128-0-18-private"
                            "crossplane.io/external-name" = "subnet-01df6730262d519b4"
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
                                kind = "Network"
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
                }
                ec2v1beta1.Subnet{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "subnet-us-west-2b-192-168-192-0-18-private"
                            "crossplane.io/external-name" = "subnet-0260ebe3484994e2b"
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
                                kind = "Network"
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
                }
                ec2v1beta1.Subnet{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "subnet-us-west-2b-192-168-64-0-18-public"
                            "crossplane.io/external-name" = "subnet-07a115654ea808b78"
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
                                kind = "Network"
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
                        ownerReferences = [
                            {
                                apiVersion = "aws.platform.upbound.io/v1alpha1"
                                blockOwnerDeletion = True
                                controller = True
                                kind = "Network"
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
                    status = ec2v1beta1.Ec2AwsmUpboundIoV1beta1VPCStatus{
                        atProvider: ec2v1beta1.Ec2AwsmUpboundIoV1beta1VPCStatusAtProvider{
                            id: "vpc-091a39902df7a340a"
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
]
items= _items
