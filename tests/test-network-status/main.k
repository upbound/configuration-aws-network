import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.aws.v1alpha1 as platformawsv1alpha1

_xr = "app-network"

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-network-status"
        spec = {
            assertResources: [
                platformawsv1alpha1.Network{
                    metadata = {
                        name = _xr
                    }
                    spec.parameters = {
                        region = "us-west-2"
                    }
                    status = {
                        networkId = "vpc-072e494f53493295e"
                        securityGroupId = "sg-02588c51ae35b709e"
                        cidrBlock = "10.0.0.0/16"
                        zones = [
                            {
                                name = "us-west-2a"
                                publicSubnetId = "subnet-0edccf697d36a3ab6"
                                privateSubnetId = "subnet-066a6b72f17012ae6"
                                natGatewayId = "nat-0852a95fd6a76cb7f"
                            }
                            {
                                name = "us-west-2b"
                                publicSubnetId = "subnet-0159a859f0395bd6b"
                                privateSubnetId = "subnet-0cb5600f886273163"
                            }
                            {
                                name = "us-west-2c"
                                publicSubnetId = "subnet-0492d95de08808515"
                                privateSubnetId = "subnet-0db69367e84f27d88"
                            }
                        ]
                    }
                }
            ]
            # The composition reads back only status.atProvider.id, keyed by
            # composition-resource-name. A fully observed network: VPC, default
            # SG, single NAT (zone a), and the public + private subnet per AZ.
            observedResources: [
                ec2v1beta1.VPC{
                    metadata.annotations = {
                        "crossplane.io/composition-resource-name" = "vpc"
                    }
                    spec.forProvider.region = "us-west-2"
                    status = {atProvider = {id = "vpc-072e494f53493295e"}}
                }
                ec2v1beta1.SecurityGroup{
                    metadata.annotations = {
                        "crossplane.io/composition-resource-name" = "sg"
                    }
                    spec.forProvider.region = "us-west-2"
                    status = {atProvider = {id = "sg-02588c51ae35b709e"}}
                }
                ec2v1beta1.NATGateway{
                    metadata.annotations = {
                        "crossplane.io/composition-resource-name" = "nat-us-west-2a"
                    }
                    spec.forProvider.region = "us-west-2"
                    status = {atProvider = {id = "nat-0852a95fd6a76cb7f"}}
                }
                ec2v1beta1.Subnet{
                    metadata.annotations = {
                        "crossplane.io/composition-resource-name" = "subnet-public-us-west-2a"
                    }
                    spec.forProvider.region = "us-west-2"
                    status = {atProvider = {id = "subnet-0edccf697d36a3ab6"}}
                }
                ec2v1beta1.Subnet{
                    metadata.annotations = {
                        "crossplane.io/composition-resource-name" = "subnet-public-us-west-2b"
                    }
                    spec.forProvider.region = "us-west-2"
                    status = {atProvider = {id = "subnet-0159a859f0395bd6b"}}
                }
                ec2v1beta1.Subnet{
                    metadata.annotations = {
                        "crossplane.io/composition-resource-name" = "subnet-public-us-west-2c"
                    }
                    spec.forProvider.region = "us-west-2"
                    status = {atProvider = {id = "subnet-0492d95de08808515"}}
                }
                ec2v1beta1.Subnet{
                    metadata.annotations = {
                        "crossplane.io/composition-resource-name" = "subnet-private-us-west-2a"
                    }
                    spec.forProvider.region = "us-west-2"
                    status = {atProvider = {id = "subnet-066a6b72f17012ae6"}}
                }
                ec2v1beta1.Subnet{
                    metadata.annotations = {
                        "crossplane.io/composition-resource-name" = "subnet-private-us-west-2b"
                    }
                    spec.forProvider.region = "us-west-2"
                    status = {atProvider = {id = "subnet-0cb5600f886273163"}}
                }
                ec2v1beta1.Subnet{
                    metadata.annotations = {
                        "crossplane.io/composition-resource-name" = "subnet-private-us-west-2c"
                    }
                    spec.forProvider.region = "us-west-2"
                    status = {atProvider = {id = "subnet-0db69367e84f27d88"}}
                }
            ]
            compositionPath: "apis/networks/composition.yaml"
            xrPath: "examples/networks/minimal-network.yaml"
            xrdPath: "apis/networks/definition.yaml"
            timeoutSeconds: 60
            validate: False
        }
    }
]
items = _items
