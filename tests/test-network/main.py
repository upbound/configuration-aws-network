import pydantic

from .model.io.k8s.apimachinery.pkg.apis.meta import v1 as metav1
from .model.io.upbound.dev.meta.compositiontest import v1alpha1 as compositiontest
from .model.io.upbound.m.aws.ec2.internetgateway import v1beta1 as igwv1beta1
from .model.io.upbound.m.aws.ec2.mainroutetableassociation import (
    v1beta1 as mrtav1beta1,
)
from .model.io.upbound.m.aws.ec2.route import v1beta1 as routev1beta1
from .model.io.upbound.m.aws.ec2.routetable import v1beta1 as rtv1beta1
from .model.io.upbound.m.aws.ec2.routetableassociation import v1beta1 as rtav1beta1
from .model.io.upbound.m.aws.ec2.securitygroup import v1beta1 as sgv1beta1
from .model.io.upbound.m.aws.ec2.securitygrouprule import v1beta1 as sgrv1beta1
from .model.io.upbound.m.aws.ec2.subnet import v1beta1 as subnetv1beta1
from .model.io.upbound.m.aws.ec2.vpc import v1beta1 as vpcv1beta1

_XR_NAME = "configuration-aws-network"
_NETWORK_ID = "configuration-aws-network"
_NETWORK_ID_LABEL = "networks.aws.platform.upbound.io/network-id"
_REGION = "us-west-2"
_PROVIDER_CONFIG = ("ProviderConfig", "default")
_MANAGEMENT_POLICIES = ["*"]


def _to_dict(model: pydantic.BaseModel) -> dict:
    # Mirror the function SDK's resource.update serialization: exclude
    # fields whose value equals the model default so the assertion shape
    # matches what the function emits.
    data = model.model_dump(exclude_defaults=True, warnings=False)
    if hasattr(model, "apiVersion") and model.apiVersion is not None:
        data["apiVersion"] = model.apiVersion
    if hasattr(model, "kind") and model.kind is not None:
        data["kind"] = model.kind
    return data


def _meta(resource_name: str, extra_labels: dict | None = None) -> metav1.ObjectMeta:
    labels = {
        "crossplane.io/composite": _XR_NAME,
        _NETWORK_ID_LABEL: _NETWORK_ID,
    }
    if extra_labels:
        labels.update(extra_labels)
    return metav1.ObjectMeta(
        annotations={"crossplane.io/composition-resource-name": resource_name},
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


def _subnet_resource_name(zone: str, cidr: str, kind: str) -> str:
    cidr_escaped = cidr.replace(".", "-").replace("/", "-")
    return f"{zone}-{cidr_escaped}-{kind}"


_pc_kind, _pc_name = _PROVIDER_CONFIG

# Subnet definitions mirror examples/networks/configuration-aws-network.yaml.
_SUBNETS = [
    ("us-west-2a", "192.168.0.0/18", "public"),
    ("us-west-2b", "192.168.64.0/18", "public"),
    ("us-west-2a", "192.168.128.0/18", "private"),
    ("us-west-2b", "192.168.192.0/18", "private"),
]


def _subnet_resource(zone: str, cidr: str, kind: str) -> dict:
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

    return _to_dict(
        subnetv1beta1.Subnet(
            metadata=_meta(
                f"subnet-{_subnet_resource_name(zone, cidr, kind)}",
                extra_labels={"zone": zone, "access": kind},
            ),
            spec=subnetv1beta1.Spec(
                forProvider=for_provider,
                managementPolicies=_MANAGEMENT_POLICIES,
                providerConfigRef=subnetv1beta1.ProviderConfigRef(
                    kind=_pc_kind, name=_pc_name
                ),
            ),
        )
    )


def _rta_resource(zone: str, cidr: str, kind: str) -> dict:
    return _to_dict(
        rtav1beta1.RouteTableAssociation(
            metadata=_meta(f"rta-{_subnet_resource_name(zone, cidr, kind)}"),
            spec=rtav1beta1.Spec(
                forProvider=rtav1beta1.ForProvider(
                    region=_REGION,
                    routeTableIdSelector=rtav1beta1.RouteTableIdSelector(
                        matchControllerRef=True
                    ),
                    subnetIdSelector=rtav1beta1.SubnetIdSelector(
                        matchControllerRef=True,
                        matchLabels={"access": kind, "zone": zone},
                    ),
                ),
                managementPolicies=_MANAGEMENT_POLICIES,
                providerConfigRef=rtav1beta1.ProviderConfigRef(
                    kind=_pc_kind, name=_pc_name
                ),
            ),
        )
    )


def _sg_rule(name: str, port: int) -> dict:
    return _to_dict(
        sgrv1beta1.SecurityGroupRule(
            metadata=_meta(name),
            spec=sgrv1beta1.Spec(
                forProvider=sgrv1beta1.ForProvider(
                    cidrBlocks=["0.0.0.0/0"],
                    description="Everywhere",
                    fromPort=port,
                    protocol="tcp",
                    region=_REGION,
                    securityGroupIdSelector=sgrv1beta1.SecurityGroupIdSelector(
                        matchControllerRef=True
                    ),
                    toPort=port,
                    type="ingress",
                ),
                managementPolicies=_MANAGEMENT_POLICIES,
                providerConfigRef=sgrv1beta1.ProviderConfigRef(
                    kind=_pc_kind, name=_pc_name
                ),
            ),
        )
    )


_assert_resources: list[dict] = [
    # XR assertion (partial — only metadata.name and a couple of parameters).
    # Built as a plain dict because the Pydantic Parameters model marks every
    # field as required, which would force us to over-specify the assertion.
    {
        "apiVersion": "aws.platform.upbound.io/v1alpha1",
        "kind": "Network",
        "metadata": {"name": _XR_NAME},
        "spec": {"parameters": {"id": _NETWORK_ID, "region": _REGION}},
    },
    # Security Group
    _to_dict(
        sgv1beta1.SecurityGroup(
            metadata=_meta("sg"),
            spec=sgv1beta1.Spec(
                forProvider=sgv1beta1.ForProvider(
                    description="Allow access to databases",
                    name="platform-ref-aws-cluster",
                    region=_REGION,
                    vpcIdSelector=sgv1beta1.VpcIdSelector(matchControllerRef=True),
                ),
                managementPolicies=_MANAGEMENT_POLICIES,
                providerConfigRef=sgv1beta1.ProviderConfigRef(
                    kind=_pc_kind, name=_pc_name
                ),
            ),
        )
    ),
    _sg_rule("sgr-mysql", 3306),
    _sg_rule("sgr-postgres", 5432),
    # Subnets — order matches the KCL test (alphabetical by resource name).
    *[_subnet_resource(*s) for s in _SUBNETS],
    # VPC
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
                    kind=_pc_kind, name=_pc_name
                ),
            ),
        )
    ),
    # Internet Gateway
    _to_dict(
        igwv1beta1.InternetGateway(
            metadata=_meta("igw"),
            spec=igwv1beta1.Spec(
                forProvider=igwv1beta1.ForProvider(
                    region=_REGION,
                    vpcIdSelector=igwv1beta1.VpcIdSelector(matchControllerRef=True),
                ),
                managementPolicies=_MANAGEMENT_POLICIES,
                providerConfigRef=igwv1beta1.ProviderConfigRef(
                    kind=_pc_kind, name=_pc_name
                ),
            ),
        )
    ),
    # Main Route Table Association
    _to_dict(
        mrtav1beta1.MainRouteTableAssociation(
            metadata=_meta("mrt"),
            spec=mrtav1beta1.Spec(
                forProvider=mrtav1beta1.ForProvider(
                    region=_REGION,
                    routeTableIdSelector=mrtav1beta1.RouteTableIdSelector(
                        matchControllerRef=True
                    ),
                    vpcIdSelector=mrtav1beta1.VpcIdSelector(matchControllerRef=True),
                ),
                managementPolicies=_MANAGEMENT_POLICIES,
                providerConfigRef=mrtav1beta1.ProviderConfigRef(
                    kind=_pc_kind, name=_pc_name
                ),
            ),
        )
    ),
    # Route
    _to_dict(
        routev1beta1.Route(
            metadata=_meta("route"),
            spec=routev1beta1.Spec(
                forProvider=routev1beta1.ForProvider(
                    destinationCidrBlock="0.0.0.0/0",
                    gatewayIdSelector=routev1beta1.GatewayIdSelector(
                        matchControllerRef=True
                    ),
                    region=_REGION,
                    routeTableIdSelector=routev1beta1.RouteTableIdSelector(
                        matchControllerRef=True
                    ),
                ),
                managementPolicies=_MANAGEMENT_POLICIES,
                providerConfigRef=routev1beta1.ProviderConfigRef(
                    kind=_pc_kind, name=_pc_name
                ),
            ),
        )
    ),
    # Route Table
    _to_dict(
        rtv1beta1.RouteTable(
            metadata=_meta("rt"),
            spec=rtv1beta1.Spec(
                forProvider=rtv1beta1.ForProvider(
                    region=_REGION,
                    vpcIdSelector=rtv1beta1.VpcIdSelector(matchControllerRef=True),
                ),
                managementPolicies=_MANAGEMENT_POLICIES,
                providerConfigRef=rtv1beta1.ProviderConfigRef(
                    kind=_pc_kind, name=_pc_name
                ),
            ),
        )
    ),
    # Route Table Associations (one per subnet)
    *[_rta_resource(*s) for s in _SUBNETS],
]


test = compositiontest.CompositionTest(
    metadata=metav1.ObjectMeta(name="test-network"),
    spec=compositiontest.Spec(
        compositionPath="apis/networks/composition.yaml",
        xrPath="examples/networks/configuration-aws-network.yaml",
        xrdPath="apis/networks/definition.yaml",
        timeoutSeconds=60,
        validate=False,
        assertResources=_assert_resources,
    ),
)
