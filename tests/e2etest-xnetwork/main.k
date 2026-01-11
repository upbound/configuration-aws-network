import models.io.upbound.awsm.v1beta1 as awsv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.aws.v1alpha1 as platformawsv1alpha1


_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2e-test-xnetwork"
        spec= {
            crossplane = {
                version = "2.0.2-up.5"
                autoUpgrade.channel = "None"
            }
            defaultConditions: ["Ready"]
            manifests: [
                platformawsv1alpha1.Network{
                    metadata = {
                        name = "configuration-aws-network"
                        namespace = "default"
                    }
                    spec = {
                        parameters = {
                            id = "configuration-aws-network"
                            region = "us-west-2"
                            vpcCidrBlock = "192.168.0.0/16"
                            subnets = [
                                {
                                    availabilityZone = "us-west-2a"
                                    $type = "public"
                                    cidrBlock = "192.168.0.0/18"
                                }
                                {
                                    availabilityZone = "us-west-2b"
                                    $type = "public"
                                    cidrBlock = "192.168.64.0/18"
                                }
                                {
                                    availabilityZone = "us-west-2a"
                                    $type = "private"
                                    cidrBlock = "192.168.128.0/18"
                                }
                                {
                                    availabilityZone = "us-west-2b"
                                    $type = "private"
                                    cidrBlock = "192.168.192.0/18"
                                }
                            ]
                        }
                    }
                }
            ]
            extraResources = [
                # Define the provider configuration
                awsv1beta1.ProviderConfig{
                    apiVersion = "aws.m.upbound.io/v1beta1"
                    metadata = {
                        name = "default"
                        namespace = "default"
                    }
                    spec = {
                        credentials = {
                            source = "Upbound"
                            upbound = {
                                webIdentity = {
                                    roleARN = "arn:aws:iam::609897127049:role/solutions-e2e-provider-aws"
                                }
                            }
                        }
                    }
                }
            ]
            skipDelete: False
            timeoutSeconds: 4500
        }
    }
]
items= _items
