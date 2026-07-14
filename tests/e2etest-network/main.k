import models.io.upbound.awsm.v1beta1 as awsv1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.aws.v1alpha1 as platformawsv1alpha1
import models.io.crossplane.apiextensions.v1alpha1 as apiextensionsv1alpha1

_items = [
    metav1alpha1.E2ETest{
        metadata.name: "e2e-test-network"
        spec= {
            crossplane.autoUpgrade.channel: "None"
            crossplane.version = "2.1.4-up.2"
            defaultConditions: ["Ready"]
            initResources: [
                # Disable default managedResourceActivationPolicy to enable only
                # required CRDs via MRAP
                apiextensionsv1alpha1.ManagedResourceActivationPolicy{
                    metadata = {
                        name = "default"
                    }
                    spec = {
                        activate: [
                            ""
                        ]
                    }
                }
            ]
            manifests: [
                platformawsv1alpha1.Network{
                    metadata = {
                        name = "app-network"
                        namespace = "default"
                    }
                    spec = {
                        parameters = {
                            region = "us-west-2"
                            availabilityZones = 3
                            cidrBlock = "10.0.0.0/16"
                            subnetStrategy = "public-private"
                            natGateway = "single"
                            defaultSecurityPolicy = "restrictive"
                            reclaimPolicy = "Delete"
                        }
                    }
                }
            ]
            extraResources = [
                # Define the provider configuration
                awsv1beta1.ProviderConfig{
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
