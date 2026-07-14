import models.io.upbound.awsm.ec2.v1beta1 as ec2v1beta1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.aws.v1alpha1 as platformawsv1alpha1

# Composition test for the minimal Network XR (examples/networks/minimal-network.yaml):
#   region us-west-2, defaults -> public-private, 3 AZs, cidr 10.0.0.0/16,
#   natGateway single, restrictive security policy, reclaimPolicy Delete.
#
# Asserts a representative slice of the rendered resources covering the new
# contract: reserved-slot subnet CIDRs (public /22, private /19), the
# network label (networks.network.platform.upbound.io/network), per-AZ
# private route tables + NAT egress, a single public route table, and the
# policy-driven default security group.

_xr = "app-network"

_pcRef = {
    kind = "ProviderConfig"
    name = "default"
}
_mgmt = ["*"]

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-network"
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
                # ---- VPC ------------------------------------------------------
                ec2v1beta1.VPC{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "vpc"
                        }
                        generateName = "app-network-"
                        labels = {
                            "crossplane.io/composite" = _xr
                            "networks.network.platform.upbound.io/network" = _xr
                        }                    }
                    spec = {
                        forProvider = {
                            cidrBlock = "10.0.0.0/16"
                            enableDnsSupport = True
                            enableDnsHostnames = True
                            region = "us-west-2"
                            tags = {
                                Name = _xr
                                "networks.network.platform.upbound.io/network" = _xr
                            }
                        }
                        managementPolicies = _mgmt
                        providerConfigRef = _pcRef
                    }
                }
                # ---- Internet gateway ----------------------------------------
                ec2v1beta1.InternetGateway{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "igw"
                        }
                        generateName = "app-network-"
                        labels = {
                            "crossplane.io/composite" = _xr
                            "networks.network.platform.upbound.io/network" = _xr
                        }                    }
                    spec = {
                        forProvider = {
                            region = "us-west-2"
                            vpcIdSelector = {matchControllerRef = True}
                        }
                        managementPolicies = _mgmt
                        providerConfigRef = _pcRef
                    }
                }
                # ---- Public subnet (reserved slot 0: parent+6 -> /22) --------
                ec2v1beta1.Subnet{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "subnet-public-us-west-2a"
                        }
                        generateName = "app-network-"
                        labels = {
                            access = "public"
                            zone = "us-west-2a"
                            "crossplane.io/composite" = _xr
                            "networks.network.platform.upbound.io/network" = _xr
                        }                    }
                    spec = {
                        forProvider = {
                            availabilityZone = "us-west-2a"
                            cidrBlock = "10.0.0.0/22"
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
                # ---- Private subnet (reserved slot 1: parent+3 -> /19) -------
                ec2v1beta1.Subnet{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "subnet-private-us-west-2a"
                        }
                        generateName = "app-network-"
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
                # ---- Default security group (restrictive: no rules) ----------
                ec2v1beta1.SecurityGroup{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "sg"
                        }
                        generateName = "app-network-"
                        labels = {
                            "crossplane.io/composite" = _xr
                            "networks.network.platform.upbound.io/network" = _xr
                        }                    }
                    spec = {
                        forProvider = {
                            name = "app-network-default"
                            description = "Default security group for network app-network"
                            region = "us-west-2"
                            vpcIdSelector = {matchControllerRef = True}
                            tags = {
                                Name = _xr
                                "networks.network.platform.upbound.io/network" = _xr
                            }
                        }
                        managementPolicies = _mgmt
                        providerConfigRef = _pcRef
                    }
                }
                # ---- Public route table + egress to IGW ----------------------
                ec2v1beta1.RouteTable{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "rt-public"
                        }
                        generateName = "app-network-"
                        labels = {
                            tier = "public"
                            "crossplane.io/composite" = _xr
                            "networks.network.platform.upbound.io/network" = _xr
                        }                    }
                    spec = {
                        forProvider = {
                            region = "us-west-2"
                            vpcIdSelector = {matchControllerRef = True}
                            tags = {
                                Name = _xr
                                "networks.network.platform.upbound.io/network" = _xr
                            }
                        }
                        managementPolicies = _mgmt
                        providerConfigRef = _pcRef
                    }
                }
                ec2v1beta1.Route{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "route-public-egress"
                        }
                        generateName = "app-network-"
                        labels = {
                            "crossplane.io/composite" = _xr
                            "networks.network.platform.upbound.io/network" = _xr
                        }                    }
                    spec = {
                        forProvider = {
                            destinationCidrBlock = "0.0.0.0/0"
                            gatewayIdSelector = {matchControllerRef = True}
                            region = "us-west-2"
                            routeTableIdSelector = {
                                matchControllerRef = True
                                matchLabels = {tier = "public"}
                            }
                        }
                        managementPolicies = _mgmt
                        providerConfigRef = _pcRef
                    }
                }
                # ---- Per-AZ private route table + egress to NAT --------------
                ec2v1beta1.RouteTable{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "rt-private-us-west-2a"
                        }
                        generateName = "app-network-"
                        labels = {
                            tier = "private"
                            zone = "us-west-2a"
                            "crossplane.io/composite" = _xr
                            "networks.network.platform.upbound.io/network" = _xr
                        }                    }
                    spec = {
                        forProvider = {
                            region = "us-west-2"
                            vpcIdSelector = {matchControllerRef = True}
                            tags = {
                                Name = _xr
                                "networks.network.platform.upbound.io/network" = _xr
                            }
                        }
                        managementPolicies = _mgmt
                        providerConfigRef = _pcRef
                    }
                }
                ec2v1beta1.Route{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "route-private-egress-us-west-2a"
                        }
                        generateName = "app-network-"
                        labels = {
                            "crossplane.io/composite" = _xr
                            "networks.network.platform.upbound.io/network" = _xr
                        }                    }
                    spec = {
                        forProvider = {
                            destinationCidrBlock = "0.0.0.0/0"
                            natGatewayIdSelector = {matchControllerRef = True}
                            region = "us-west-2"
                            routeTableIdSelector = {
                                matchControllerRef = True
                                matchLabels = {tier = "private", zone = "us-west-2a"}
                            }
                        }
                        managementPolicies = _mgmt
                        providerConfigRef = _pcRef
                    }
                }
                # ---- NAT egress: single NAT in zone a ------------------------
                ec2v1beta1.EIP{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "eip-us-west-2a"
                        }
                        generateName = "app-network-"
                        labels = {
                            "nat-zone" = "us-west-2a"
                            "crossplane.io/composite" = _xr
                            "networks.network.platform.upbound.io/network" = _xr
                        }                    }
                    spec = {
                        forProvider = {
                            domain = "vpc"
                            region = "us-west-2"
                            tags = {
                                Name = _xr
                                "networks.network.platform.upbound.io/network" = _xr
                            }
                        }
                        managementPolicies = _mgmt
                        providerConfigRef = _pcRef
                    }
                }
                ec2v1beta1.NATGateway{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "nat-us-west-2a"
                        }
                        generateName = "app-network-"
                        labels = {
                            zone = "us-west-2a"
                            "crossplane.io/composite" = _xr
                            "networks.network.platform.upbound.io/network" = _xr
                        }                    }
                    spec = {
                        forProvider = {
                            region = "us-west-2"
                            subnetIdSelector = {
                                matchControllerRef = True
                                matchLabels = {access = "public", zone = "us-west-2a"}
                            }
                            allocationIdSelector = {
                                matchControllerRef = True
                                matchLabels = {"nat-zone" = "us-west-2a"}
                            }
                            tags = {
                                Name = _xr
                                "networks.network.platform.upbound.io/network" = _xr
                            }
                        }
                        managementPolicies = _mgmt
                        providerConfigRef = _pcRef
                    }
                }
                # ---- Route table association (public, zone a) ----------------
                ec2v1beta1.RouteTableAssociation{
                    metadata = {
                        annotations = {
                            "crossplane.io/composition-resource-name" = "rta-subnet-public-us-west-2a"
                        }
                        generateName = "app-network-"
                        labels = {
                            "crossplane.io/composite" = _xr
                            "networks.network.platform.upbound.io/network" = _xr
                        }                    }
                    spec = {
                        forProvider = {
                            region = "us-west-2"
                            routeTableIdSelector = {
                                matchControllerRef = True
                                matchLabels = {tier = "public"}
                            }
                            subnetIdSelector = {
                                matchControllerRef = True
                                matchLabels = {access = "public", zone = "us-west-2a"}
                            }
                        }
                        managementPolicies = _mgmt
                        providerConfigRef = _pcRef
                    }
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
