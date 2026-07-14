import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.aws.v1alpha1 as platformawsv1alpha1

# Composition test for the per-slot subnet CIDR override
# (examples/networks/manual-network.yaml):
#   region us-west-2, 2 AZs, cidr 10.0.0.0/16, public-private, natGateway single,
#   with overrides.subnetCidrs setting the public AND private CIDR for both AZs.
#
# Every slot is overridden here, so this asserts the fully-manual case:
#   - each subnet takes its explicit override CIDR (no computed slot addresses),
#   - only the address is driven by the override — names/labels/structure follow
#     the same "subnet-<tier>-<az>" grid the computed path produces.

_xr = "manual-network"

_pcRef = {
    kind = "ProviderConfig"
    name = "default"
}
_mgmt = ["*"]

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-network-overrides"
        spec = {
            assertResources: [
                # ---- Composite ------------------------------------------------
                platformawsv1alpha1.Network{
                    metadata = {
                        name = _xr
                    }
                    spec.parameters = {
                        region = "us-west-2"
                        availabilityZones = 2
                    }
                }
                # ---- 2a public: OVERRIDDEN (10.0.0.0/24) ---------------------
                ec2v1beta1.Subnet{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "subnet-public-us-west-2a"
                        }
                        generateName = "manual-network-"
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
                # ---- 2a private: OVERRIDDEN (10.0.10.0/23) -------------------
                ec2v1beta1.Subnet{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "subnet-private-us-west-2a"
                        }
                        generateName = "manual-network-"
                        labels = {
                            access = "private"
                            zone = "us-west-2a"
                            "crossplane.io/composite" = _xr
                            "networks.network.platform.upbound.io/network" = _xr
                        }                    }
                    spec = {
                        forProvider = {
                            availabilityZone = "us-west-2a"
                            cidrBlock = "10.0.10.0/23"
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
                # ---- 2b public: OVERRIDDEN (10.0.30.0/23) --------------------
                ec2v1beta1.Subnet{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "subnet-public-us-west-2b"
                        }
                        generateName = "manual-network-"
                        labels = {
                            access = "public"
                            zone = "us-west-2b"
                            "crossplane.io/composite" = _xr
                            "networks.network.platform.upbound.io/network" = _xr
                        }                    }
                    spec = {
                        forProvider = {
                            availabilityZone = "us-west-2b"
                            cidrBlock = "10.0.30.0/23"
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
                # ---- 2b private: OVERRIDDEN (10.0.20.0/23) -------------------
                ec2v1beta1.Subnet{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "subnet-private-us-west-2b"
                        }
                        generateName = "manual-network-"
                        labels = {
                            access = "private"
                            zone = "us-west-2b"
                            "crossplane.io/composite" = _xr
                            "networks.network.platform.upbound.io/network" = _xr
                        }                    }
                    spec = {
                        forProvider = {
                            availabilityZone = "us-west-2b"
                            cidrBlock = "10.0.20.0/23"
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
            ]
            compositionPath: "apis/networks/composition.yaml"
            xrPath: "examples/networks/manual-network.yaml"
            xrdPath: "apis/networks/definition.yaml"
            timeoutSeconds: 60
            validate: False
        }
    }
]
items = _items
