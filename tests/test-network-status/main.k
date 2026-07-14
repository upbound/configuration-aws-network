import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.io.upbound.platform.aws.v1alpha1 as platformawsv1alpha1

# Status test for the minimal Network XR (examples/networks/minimal-network.yaml).
#
# Scope note: this asserts only the SPEC-DERIVED status fields — status.cidrBlock
# and the zone list keyed by name. The observed-derived IDs (networkId,
# securityGroupId, zones[].publicSubnetId/privateSubnetId/natGatewayId) are NOT
# asserted here because the local test harness (up v0.51.0) does not feed observed
# composed resources into the function's option("params").ocds — it is always an
# empty dict, so those IDs can never populate under `up test`/`up composition
# render`. The composition's observed->status mapping is correct in-cluster (a live
# Network XR reports networkId, securityGroupId, and per-zone subnet IDs); it just
# isn't exercisable locally. Keep this test to lock the spec-derived status shape.

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
                        cidrBlock = "10.0.0.0/16"
                        zones = [
                            {name = "us-west-2a"}
                            {name = "us-west-2b"}
                            {name = "us-west-2c"}
                        ]
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
