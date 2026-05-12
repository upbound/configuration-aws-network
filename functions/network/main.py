from crossplane.function import resource
from crossplane.function.proto.v1 import run_function_pb2 as fnv1

from .model.io.k8s.apimachinery.pkg.apis.meta import v1 as metav1
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
from .model.io.upbound.platform.aws.network import v1alpha1 as networkv1alpha1

_NETWORK_ID_LABEL = "networks.aws.platform.upbound.io/network-id"


def _cidr_escaped(cidr: str) -> str:
    return cidr.replace(".", "-").replace("/", "-")


def _format_subnet(s: networkv1alpha1.Subnet) -> str:
    return f"{s.availabilityZone}-{_cidr_escaped(s.cidrBlock)}-{s.type}"


def _external_name(req: fnv1.RunFunctionRequest, name: str) -> str | None:
    res = req.observed.resources.get(name)
    if res is None:
        return None
    annotations = (
        resource.struct_to_dict(res.resource)
        .get("metadata", {})
        .get("annotations", {})
    )
    return annotations.get("crossplane.io/external-name")


def _observed_vpc_id(req: fnv1.RunFunctionRequest) -> str | None:
    res = req.observed.resources.get("vpc")
    if res is None:
        return None
    vpc = vpcv1beta1.VPC.model_validate(resource.struct_to_dict(res.resource))
    if not vpc.status or not vpc.status.atProvider:
        return None
    return vpc.status.atProvider.id


def _observed_sg_id(req: fnv1.RunFunctionRequest) -> str | None:
    res = req.observed.resources.get("sg")
    if res is None:
        return None
    sg = sgv1beta1.SecurityGroup.model_validate(resource.struct_to_dict(res.resource))
    if not sg.status or not sg.status.atProvider:
        return None
    return sg.status.atProvider.id


def compose(req: fnv1.RunFunctionRequest, rsp: fnv1.RunFunctionResponse):
    xr = networkv1alpha1.Network(**resource.struct_to_dict(req.observed.composite.resource))
    params = xr.spec.parameters

    provider_config_kind = "ProviderConfig"
    provider_config_name = params.providerConfigName
    management_policies = params.managementPolicies
    region = params.region
    network_id = params.id
    xr_name = xr.metadata.name if xr.metadata and xr.metadata.name else network_id

    base_labels = {_NETWORK_ID_LABEL: network_id}

    # VPC
    resource.update(
        rsp.desired.resources["vpc"],
        vpcv1beta1.VPC(
            metadata=metav1.ObjectMeta(labels=base_labels),
            spec=vpcv1beta1.Spec(
                forProvider=vpcv1beta1.ForProvider(
                    cidrBlock=params.vpcCidrBlock,
                    enableDnsHostnames=True,
                    enableDnsSupport=True,
                    tags={"Name": xr_name},
                    region=region,
                ),
                managementPolicies=management_policies,
                providerConfigRef=vpcv1beta1.ProviderConfigRef(
                    kind=provider_config_kind, name=provider_config_name
                ),
            ),
        ),
    )

    # Internet Gateway
    resource.update(
        rsp.desired.resources["igw"],
        igwv1beta1.InternetGateway(
            metadata=metav1.ObjectMeta(labels=base_labels),
            spec=igwv1beta1.Spec(
                forProvider=igwv1beta1.ForProvider(
                    region=region,
                    vpcIdSelector=igwv1beta1.VpcIdSelector(matchControllerRef=True),
                ),
                managementPolicies=management_policies,
                providerConfigRef=igwv1beta1.ProviderConfigRef(
                    kind=provider_config_kind, name=provider_config_name
                ),
            ),
        ),
    )

    # Subnets
    for s in params.subnets:
        is_public = s.type == "public"
        access = "public" if is_public else "private"
        if is_public:
            tags = {
                "kubernetes.io/role/elb": "1",
                _NETWORK_ID_LABEL: network_id,
            }
        else:
            tags = {"kubernetes.io/role/internal-elb": "1"}

        subnet_labels = {
            "zone": s.availabilityZone,
            "access": access,
            _NETWORK_ID_LABEL: network_id,
        }

        for_provider = subnetv1beta1.ForProvider(
            availabilityZone=s.availabilityZone,
            cidrBlock=s.cidrBlock,
            region=region,
            tags=tags,
            vpcIdSelector=subnetv1beta1.VpcIdSelector(matchControllerRef=True),
        )
        if is_public:
            for_provider.mapPublicIpOnLaunch = True

        resource.update(
        rsp.desired.resources[f"subnet-{_format_subnet(s)}"],
            subnetv1beta1.Subnet(
                metadata=metav1.ObjectMeta(labels=subnet_labels),
                spec=subnetv1beta1.Spec(
                    forProvider=for_provider,
                    managementPolicies=management_policies,
                    providerConfigRef=subnetv1beta1.ProviderConfigRef(
                        kind=provider_config_kind, name=provider_config_name
                    ),
                ),
            ),
        )

    # Route Table
    resource.update(
        rsp.desired.resources["rt"],
        rtv1beta1.RouteTable(
            metadata=metav1.ObjectMeta(labels=base_labels),
            spec=rtv1beta1.Spec(
                forProvider=rtv1beta1.ForProvider(
                    region=region,
                    vpcIdSelector=rtv1beta1.VpcIdSelector(matchControllerRef=True),
                ),
                managementPolicies=management_policies,
                providerConfigRef=rtv1beta1.ProviderConfigRef(
                    kind=provider_config_kind, name=provider_config_name
                ),
            ),
        ),
    )

    # Route
    resource.update(
        rsp.desired.resources["route"],
        routev1beta1.Route(
            metadata=metav1.ObjectMeta(labels=base_labels),
            spec=routev1beta1.Spec(
                forProvider=routev1beta1.ForProvider(
                    destinationCidrBlock="0.0.0.0/0",
                    gatewayIdSelector=routev1beta1.GatewayIdSelector(
                        matchControllerRef=True
                    ),
                    region=region,
                    routeTableIdSelector=routev1beta1.RouteTableIdSelector(
                        matchControllerRef=True
                    ),
                ),
                managementPolicies=management_policies,
                providerConfigRef=routev1beta1.ProviderConfigRef(
                    kind=provider_config_kind, name=provider_config_name
                ),
            ),
        ),
    )

    # Main Route Table Association
    resource.update(
        rsp.desired.resources["mrt"],
        mrtav1beta1.MainRouteTableAssociation(
            metadata=metav1.ObjectMeta(labels=base_labels),
            spec=mrtav1beta1.Spec(
                forProvider=mrtav1beta1.ForProvider(
                    region=region,
                    routeTableIdSelector=mrtav1beta1.RouteTableIdSelector(
                        matchControllerRef=True
                    ),
                    vpcIdSelector=mrtav1beta1.VpcIdSelector(matchControllerRef=True),
                ),
                managementPolicies=management_policies,
                providerConfigRef=mrtav1beta1.ProviderConfigRef(
                    kind=provider_config_kind, name=provider_config_name
                ),
            ),
        ),
    )

    # Route Table Associations (per subnet)
    for s in params.subnets:
        access = "public" if s.type == "public" else "private"
        resource.update(
        rsp.desired.resources[f"rta-{_format_subnet(s)}"],
            rtav1beta1.RouteTableAssociation(
                metadata=metav1.ObjectMeta(labels=base_labels),
                spec=rtav1beta1.Spec(
                    forProvider=rtav1beta1.ForProvider(
                        region=region,
                        routeTableIdSelector=rtav1beta1.RouteTableIdSelector(
                            matchControllerRef=True
                        ),
                        subnetIdSelector=rtav1beta1.SubnetIdSelector(
                            matchControllerRef=True,
                            matchLabels={
                                "access": access,
                                "zone": s.availabilityZone,
                            },
                        ),
                    ),
                    managementPolicies=management_policies,
                    providerConfigRef=rtav1beta1.ProviderConfigRef(
                        kind=provider_config_kind, name=provider_config_name
                    ),
                ),
            ),
        )

    # Security Group
    resource.update(
        rsp.desired.resources["sg"],
        sgv1beta1.SecurityGroup(
            metadata=metav1.ObjectMeta(labels=base_labels),
            spec=sgv1beta1.Spec(
                forProvider=sgv1beta1.ForProvider(
                    description="Allow access to databases",
                    name="platform-ref-aws-cluster",
                    region=region,
                    vpcIdSelector=sgv1beta1.VpcIdSelector(matchControllerRef=True),
                ),
                managementPolicies=management_policies,
                providerConfigRef=sgv1beta1.ProviderConfigRef(
                    kind=provider_config_kind, name=provider_config_name
                ),
            ),
        ),
    )

    # Security Group Rules
    for rule_name, port in (("sgr-postgres", 5432), ("sgr-mysql", 3306)):
        resource.update(
        rsp.desired.resources[rule_name],
            sgrv1beta1.SecurityGroupRule(
                metadata=metav1.ObjectMeta(labels=base_labels),
                spec=sgrv1beta1.Spec(
                    forProvider=sgrv1beta1.ForProvider(
                        cidrBlocks=["0.0.0.0/0"],
                        description="Everywhere",
                        fromPort=port,
                        protocol="tcp",
                        region=region,
                        securityGroupIdSelector=sgrv1beta1.SecurityGroupIdSelector(
                            matchControllerRef=True
                        ),
                        toPort=port,
                        type="ingress",
                    ),
                    managementPolicies=management_policies,
                    providerConfigRef=sgrv1beta1.ProviderConfigRef(
                        kind=provider_config_kind, name=provider_config_name
                    ),
                ),
            ),
        )

    # Status: derive from observed resources, mirroring the previous KCL logic.
    public_subnet_ids: list[str] = []
    private_subnet_ids: list[str] = []
    for s in params.subnets:
        external_name = _external_name(req, f"subnet-{_format_subnet(s)}")
        if external_name is None:
            continue
        if s.type == "public":
            public_subnet_ids.append(external_name)
        else:
            private_subnet_ids.append(external_name)

    status: dict = {
        "subnetIds": public_subnet_ids + private_subnet_ids,
        "publicSubnetIds": public_subnet_ids,
        "privateSubnetIds": private_subnet_ids,
        "securityGroupIds": [_observed_sg_id(req) or ""],
    }
    vpc_id = _observed_vpc_id(req)
    if vpc_id:
        status["vpcId"] = vpc_id

    resource.update(rsp.desired.composite, {"status": status})
