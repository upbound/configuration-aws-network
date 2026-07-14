import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.aws.v1alpha1 as platformawsv1alpha1

# Composition test for the PARTIAL override / computed-fallback path
# (examples/networks/fallback-network.yaml):
#   region us-west-2, 3 AZs (default), cidr 10.0.0.0/16, public-private,
#   natGateway single, with overrides.subnetCidrs setting ONLY 2a public.
#
# Proves per-slot fallback: an overridden slot takes its explicit CIDR while
# every unset slot — including the sibling tier in the same AZ — keeps its
# computed reserved-slot address.
#   - 2a public   -> OVERRIDDEN   10.0.0.0/24
#   - 2a private  -> COMPUTED     10.0.32.0/19  (slot i=0, parent+3)
#   - 2b public   -> COMPUTED     10.0.4.0/22   (slot i=1, parent+6)

_xr = "fallback-network"

_pcRef = {
    kind = "ProviderConfig"
    name = "default"
}
_mgmt = ["*"]

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-network-fallback"
        spec = {
            assertResources: [
                # ---- Composite ------------------------------------------------
                platformawsv1alpha1.Network{
                    metadata = {
                        name = _xr
                    }
                    spec.parameters = {
                        region = "us-west-2"
                    }
                }
                # ---- 2a public: OVERRIDDEN (10.0.0.0/24, not computed /22) ----
                ec2v1beta1.Subnet{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "subnet-public-us-west-2a"
                        }
                        generateName = "fallback-network-"
                        labels = {
                            access = "public"
                            zone = "us-west-2a"
                            "crossplane.io/composite" = _xr
                            "networks.network.platform.upbound.io/network" = _xr
                        }                    }
                    spec = {
                        forProvider = {
                            availabilityZone = "us-west-2a"
                            cidrBlock = "10.0.0.0/24"
                            mapPublicIpOnLaunch = True
                            region = "us-west-2"
                            tags = {
                                Name = _xr
                                "networks.network.platform.upbound.io/network" = _xr
                                "kubernetes.io/role/elb" = "1"
                            }
                            vpcIdSelector = {matchControllerRef = True}
                        }
                        managementPolicies = _mgmt
                        providerConfigRef = _pcRef
                    }
                }
                # ---- 2a private: FALLBACK to computed slot i=0 (10.0.32.0/19) -
                # The key assertion: the sibling tier of an overridden slot still
                # computes — override is per-slot, not per-AZ.
                ec2v1beta1.Subnet{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "subnet-private-us-west-2a"
                        }
                        generateName = "fallback-network-"
                        labels = {
                            access = "private"
                            zone = "us-west-2a"
                            "crossplane.io/composite" = _xr
                            "networks.network.platform.upbound.io/network" = _xr
                        }                    }
                    spec = {
                        forProvider = {
                            availabilityZone = "us-west-2a"
                            cidrBlock = "10.0.32.0/19"
                            region = "us-west-2"
                            tags = {
                                Name = _xr
                                "networks.network.platform.upbound.io/network" = _xr
                                "kubernetes.io/role/internal-elb" = "1"
                            }
                            vpcIdSelector = {matchControllerRef = True}
                        }
                        managementPolicies = _mgmt
                        providerConfigRef = _pcRef
                    }
                }
                # ---- 2b public: FULLY COMPUTED (slot i=1 -> 10.0.4.0/22) ------
                ec2v1beta1.Subnet{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "subnet-public-us-west-2b"
                        }
                        generateName = "fallback-network-"
                        labels = {
                            access = "public"
                            zone = "us-west-2b"
                            "crossplane.io/composite" = _xr
                            "networks.network.platform.upbound.io/network" = _xr
                        }                    }
                    spec = {
                        forProvider = {
                            availabilityZone = "us-west-2b"
                            cidrBlock = "10.0.4.0/22"
                            mapPublicIpOnLaunch = True
                            region = "us-west-2"
                            tags = {
                                Name = _xr
                                "networks.network.platform.upbound.io/network" = _xr
                                "kubernetes.io/role/elb" = "1"
                            }
                            vpcIdSelector = {matchControllerRef = True}
                        }
                        managementPolicies = _mgmt
                        providerConfigRef = _pcRef
                    }
                }
            ]
            compositionPath: "apis/networks/composition.yaml"
            xrPath: "examples/networks/fallback-network.yaml"
            xrdPath: "apis/networks/definition.yaml"
            timeoutSeconds: 60
            validate: False
        }
    }
]
items = _items
