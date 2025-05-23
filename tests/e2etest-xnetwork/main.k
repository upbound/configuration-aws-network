import models.io.upbound.aws.v1beta1 as awsv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.aws.v1alpha1 as platformawsv1alpha1

shouldfail

_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2e-test-xnetwork"
        spec= {
            crossplane.autoUpgrade.channel: "Rapid"
            defaultConditions: ["Ready"]
            manifests: [
                platformawsv1alpha1.XNetwork{
                    metadata = {
                        name = "configuration-aws-network"
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
                    metadata.name = "default"
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
