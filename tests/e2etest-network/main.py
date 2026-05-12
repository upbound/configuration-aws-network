import pydantic

from .model.io.crossplane.apiextensions.managedresourceactivationpolicy import (
    v1alpha1 as mrapv1alpha1,
)
from .model.io.k8s.apimachinery.pkg.apis.meta import v1 as metav1
from .model.io.upbound.dev.meta.e2etest import v1alpha1 as e2etestv1alpha1
from .model.io.upbound.m.aws.providerconfig import v1beta1 as awspcv1beta1
from .model.io.upbound.platform.aws.network import v1alpha1 as networkv1alpha1


def _fixture(model: pydantic.BaseModel) -> dict:
    data = model.model_dump(exclude_none=True, warnings=False)
    if hasattr(model, "apiVersion") and model.apiVersion is not None:
        data["apiVersion"] = model.apiVersion
    if hasattr(model, "kind") and model.kind is not None:
        data["kind"] = model.kind
    return data


test = e2etestv1alpha1.E2ETest(
    metadata=metav1.ObjectMeta(name="e2e-test-network"),
    spec=e2etestv1alpha1.Spec(
        crossplane=e2etestv1alpha1.Crossplane(
            autoUpgrade=e2etestv1alpha1.AutoUpgrade(channel="None"),
            version="2.1.4-up.2",
        ),
        defaultConditions=["Ready"],
        initResources=[
            # Disable the default ManagedResourceActivationPolicy so only the
            # CRDs the test needs (activated via the configuration's own MRAP)
            # are enabled.
            _fixture(
                mrapv1alpha1.ManagedResourceActivationPolicy(
                    metadata=metav1.ObjectMeta(name="default"),
                    spec=mrapv1alpha1.Spec(activate=[""]),
                ),
            ),
        ],
        manifests=[
            _fixture(
                networkv1alpha1.Network(
                    metadata=metav1.ObjectMeta(
                        name="configuration-aws-network",
                        namespace="default",
                    ),
                    spec=networkv1alpha1.Spec(
                        parameters=networkv1alpha1.Parameters(
                            id="configuration-aws-network",
                            region="us-west-2",
                            vpcCidrBlock="192.168.0.0/16",
                            managementPolicies=["*"],
                            providerConfigName="default",
                            subnets=[
                                networkv1alpha1.Subnet(
                                    availabilityZone="us-west-2a",
                                    type="public",
                                    cidrBlock="192.168.0.0/18",
                                ),
                                networkv1alpha1.Subnet(
                                    availabilityZone="us-west-2b",
                                    type="public",
                                    cidrBlock="192.168.64.0/18",
                                ),
                                networkv1alpha1.Subnet(
                                    availabilityZone="us-west-2a",
                                    type="private",
                                    cidrBlock="192.168.128.0/18",
                                ),
                                networkv1alpha1.Subnet(
                                    availabilityZone="us-west-2b",
                                    type="private",
                                    cidrBlock="192.168.192.0/18",
                                ),
                            ],
                        ),
                    ),
                ),
            ),
        ],
        extraResources=[
            _fixture(
                awspcv1beta1.ProviderConfig(
                    metadata=metav1.ObjectMeta(
                        name="default",
                        namespace="default",
                    ),
                    spec=awspcv1beta1.Spec(
                        credentials=awspcv1beta1.Credentials(
                            source="Upbound",
                            upbound=awspcv1beta1.Upbound(
                                webIdentity=awspcv1beta1.WebIdentity(
                                    roleARN="arn:aws:iam::609897127049:role/solutions-e2e-provider-aws",
                                ),
                            ),
                        ),
                    ),
                ),
            ),
        ],
        skipDelete=False,
        timeoutSeconds=4500,
    ),
)
