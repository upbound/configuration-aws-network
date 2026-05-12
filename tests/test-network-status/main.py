import pydantic

from .model.io.k8s.apimachinery.pkg.apis.meta import v1 as metav1
from .model.io.upbound.dev.meta.compositiontest import v1alpha1 as compositiontest
from .model.io.upbound.m.aws.ec2.securitygroup import v1beta1 as sgv1beta1
from .model.io.upbound.m.aws.ec2.subnet import v1beta1 as subnetv1beta1
from .model.io.upbound.m.aws.ec2.vpc import v1beta1 as vpcv1beta1

_XR_NAME = "configuration-aws-network"
_NETWORK_ID = "configuration-aws-network"
_NETWORK_ID_LABEL = "networks.aws.platform.upbound.io/network-id"
_REGION = "us-west-2"
_PROVIDER_CONFIG_KIND = "ProviderConfig"
_PROVIDER_CONFIG_NAME = "default"
_MANAGEMENT_POLICIES = ["*"]

# External names of the simulated AWS resources, keyed by composition-resource-name.
# Each subnet's external-name flows through the XR status as a subnetId; VPC and
# SG IDs come from .status.atProvider.id.
_VPC_ID = "vpc-091a39902df7a340a"
_SG_ID = "sg-0be55443dc4247834"
_SUBNET_2A_PUBLIC_ID = "subnet-0775f953a8271ef84"
_SUBNET_2B_PUBLIC_ID = "subnet-07a115654ea808b78"
_SUBNET_2A_PRIVATE_ID = "subnet-01df6730262d519b4"
_SUBNET_2B_PRIVATE_ID = "subnet-0260ebe3484994e2b"


def _to_dict(model: pydantic.BaseModel) -> dict:
    # Mirror the function SDK's resource.update serialization so observed
    # fixtures match the shape the function sees from Crossplane (defaults
    # filled in by the controller, not echoed back through the function).
    data = model.model_dump(exclude_defaults=True, warnings=False)
    if hasattr(model, "apiVersion") and model.apiVersion is not None:
        data["apiVersion"] = model.apiVersion
    if hasattr(model, "kind") and model.kind is not None:
        data["kind"] = model.kind
    return data


def _meta(
    resource_name: str,
    external_name: str | None = None,
    extra_labels: dict | None = None,
) -> metav1.ObjectMeta:
    annotations = {"crossplane.io/composition-resource-name": resource_name}
    if external_name is not None:
        annotations["crossplane.io/external-name"] = external_name
    labels = {
        "crossplane.io/composite": _XR_NAME,
        _NETWORK_ID_LABEL: _NETWORK_ID,
    }
    if extra_labels:
        labels.update(extra_labels)
    return metav1.ObjectMeta(
        annotations=annotations,
        generateName=f"{_XR_NAME}-",
        labels=labels,
        ownerReferences=[
            metav1.OwnerReference(
                apiVersion="aws.platform.upbound.io/v1alpha1",
                blockOwnerDeletion=True,
                controller=True,
                kind="Network",
                name=_XR_NAME,
                uid="",
            )
        ],
    )


def _subnet_observed(
    zone: str, cidr: str, kind: str, external_name: str
) -> dict:
    is_public = kind == "public"
    if is_public:
        tags = {
            "kubernetes.io/role/elb": "1",
            _NETWORK_ID_LABEL: _NETWORK_ID,
        }
    else:
        tags = {"kubernetes.io/role/internal-elb": "1"}

    for_provider = subnetv1beta1.ForProvider(
        availabilityZone=zone,
        cidrBlock=cidr,
        region=_REGION,
        tags=tags,
        vpcIdSelector=subnetv1beta1.VpcIdSelector(matchControllerRef=True),
    )
    if is_public:
        for_provider.mapPublicIpOnLaunch = True

    cidr_escaped = cidr.replace(".", "-").replace("/", "-")
    return _to_dict(
        subnetv1beta1.Subnet(
            metadata=_meta(
                f"subnet-{zone}-{cidr_escaped}-{kind}",
                external_name=external_name,
                extra_labels={"zone": zone, "access": kind},
            ),
            spec=subnetv1beta1.Spec(
                forProvider=for_provider,
                managementPolicies=_MANAGEMENT_POLICIES,
                providerConfigRef=subnetv1beta1.ProviderConfigRef(
                    kind=_PROVIDER_CONFIG_KIND, name=_PROVIDER_CONFIG_NAME
                ),
            ),
        )
    )


_observed_resources: list[dict] = [
    _to_dict(
        sgv1beta1.SecurityGroup(
            metadata=metav1.ObjectMeta(
                annotations={
                    "crossplane.io/composition-resource-name": "sg",
                    "crossplane.io/external-name": _SG_ID,
                }
            ),
            spec=sgv1beta1.Spec(
                forProvider=sgv1beta1.ForProvider(
                    description="Allow access to databases",
                    name="platform-ref-aws-cluster",
                    region=_REGION,
                    vpcIdSelector=sgv1beta1.VpcIdSelector(matchControllerRef=True),
                ),
                managementPolicies=_MANAGEMENT_POLICIES,
                providerConfigRef=sgv1beta1.ProviderConfigRef(
                    kind=_PROVIDER_CONFIG_KIND, name=_PROVIDER_CONFIG_NAME
                ),
            ),
            status=sgv1beta1.Status(
                atProvider=sgv1beta1.AtProvider(id=_SG_ID),
            ),
        )
    ),
    _subnet_observed("us-west-2a", "192.168.0.0/18", "public", _SUBNET_2A_PUBLIC_ID),
    _subnet_observed(
        "us-west-2a", "192.168.128.0/18", "private", _SUBNET_2A_PRIVATE_ID
    ),
    _subnet_observed(
        "us-west-2b", "192.168.192.0/18", "private", _SUBNET_2B_PRIVATE_ID
    ),
    _subnet_observed("us-west-2b", "192.168.64.0/18", "public", _SUBNET_2B_PUBLIC_ID),
    _to_dict(
        vpcv1beta1.VPC(
            metadata=_meta("vpc"),
            spec=vpcv1beta1.Spec(
                forProvider=vpcv1beta1.ForProvider(
                    cidrBlock="192.168.0.0/16",
                    enableDnsHostnames=True,
                    enableDnsSupport=True,
                    region=_REGION,
                    tags={"Name": _XR_NAME},
                ),
                managementPolicies=_MANAGEMENT_POLICIES,
                providerConfigRef=vpcv1beta1.ProviderConfigRef(
                    kind=_PROVIDER_CONFIG_KIND, name=_PROVIDER_CONFIG_NAME
                ),
            ),
            status=vpcv1beta1.Status(
                atProvider=vpcv1beta1.AtProvider(id=_VPC_ID),
            ),
        )
    ),
]

# The XR assertion uses a plain dict so we can express a partial assertion
# without satisfying every required field on the Pydantic Parameters model.
_xr_assertion: dict = {
    "apiVersion": "aws.platform.upbound.io/v1alpha1",
    "kind": "Network",
    "metadata": {"name": _XR_NAME},
    "spec": {"parameters": {"id": _NETWORK_ID, "region": _REGION}},
    "status": {
        "securityGroupIds": [_SG_ID],
        "privateSubnetIds": [_SUBNET_2A_PRIVATE_ID, _SUBNET_2B_PRIVATE_ID],
        "publicSubnetIds": [_SUBNET_2A_PUBLIC_ID, _SUBNET_2B_PUBLIC_ID],
        "subnetIds": [
            _SUBNET_2A_PUBLIC_ID,
            _SUBNET_2B_PUBLIC_ID,
            _SUBNET_2A_PRIVATE_ID,
            _SUBNET_2B_PRIVATE_ID,
        ],
        "vpcId": _VPC_ID,
    },
}


test = compositiontest.CompositionTest(
    metadata=metav1.ObjectMeta(name="test-network"),
    spec=compositiontest.Spec(
        compositionPath="apis/networks/composition.yaml",
        xrPath="examples/networks/configuration-aws-network.yaml",
        xrdPath="apis/networks/definition.yaml",
        timeoutSeconds=60,
        validate=False,
        assertResources=[_xr_assertion],
        observedResources=_observed_resources,
    ),
)
