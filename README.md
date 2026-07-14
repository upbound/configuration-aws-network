# AWS Network Configuration

An [Upbound](https://cloud.upbound.io) project that exposes a single, declarative
**Network** API for AWS. You describe the network you want; the composition
allocates the VPC, subnets, gateways, route tables, and security groups to match.

This configuration is built as an **API program**, not a bundle of resources: the
`Network` XRD is a stable contract, and the composition behind it is a swappable
implementation. Provider resources, provider field names, and CIDR math live only
in the implementation, so the underlying plumbing can change (provider upgrades,
new AWS features, layout tweaks) without breaking the API your consumers depend on.

## Layout

| Path | Role |
| --- | --- |
| [`apis/networks/definition.yaml`](/apis/networks/definition.yaml) | The **contract** — the `Network` XRD (`aws.platform.upbound.io/v1alpha1`, Crossplane v2 `Namespaced` scope). |
| [`apis/networks/composition.yaml`](/apis/networks/composition.yaml) | The **implementation** — a Pipeline composition delegating to the embedded function. |
| [`functions/network/main.k`](/functions/network/main.k) | The composition logic (KCL), the only place provider resources and CIDR math appear. |
| [`apis/networks/mrap.yaml`](/apis/networks/mrap.yaml) | `ManagedResourceActivationPolicy` activating only the CRDs this configuration needs. |
| [`examples/networks`](/examples/networks) | Ready-to-apply `Network` resources. |
| [`tests`](/tests) | Composition and end-to-end tests. |

Dependencies: `provider-aws-ec2` (v2) and `function-auto-ready`.

## The Network API

The API is **intent-based**: you express what varies for your network, and nothing
about how it is built. The only required parameter is `region` — a complete
network is a single field:

```yaml
apiVersion: aws.platform.upbound.io/v1alpha1
kind: Network
metadata:
  namespace: default
  name: app-network
spec:
  parameters:
    region: us-west-2
```

### Parameters

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `region` | string | — (required) | Cloud region, e.g. `us-west-2`. |
| `availabilityZones` | integer (1–6) | `3` | Number of AZs to span. Subnets come from fixed, pre-reserved slots, so increasing this adds subnets without resizing or replacing existing ones. |
| `cidrBlock` | string | `10.0.0.0/16` | Address space for the network (use `/22` or larger). Slots are allocated at fixed offsets, so growth is always additive. |
| `subnetStrategy` | enum: `public-private`, `private-only`, `public-only` | `public-private` | Which subnet tiers to activate. Tier offsets are fixed, so changing strategy later activates a reserved tier without touching existing subnets. |
| `natGateway` | enum: `per-az`, `single`, `none` | `single` | Egress strategy for private subnets. `per-az` gives each zone an independent egress path; `single` trades that for cost; `none` means no internet egress (pair with VPC endpoints). |
| `dnsSupport` | boolean | `true` | Enable DNS resolution in the VPC. |
| `dnsHostnames` | boolean | `true` | Enable DNS hostnames in the VPC. |
| `defaultSecurityPolicy` | enum: `restrictive`, `permissive` | `restrictive` | `restrictive` creates the default security group with no ingress rules (workloads bring their own); `permissive` allows all traffic originating within the network CIDR. |
| `tags` | map[string]string | `{}` | Merged into every resource the network creates. |
| `reclaimPolicy` | enum: `Delete`, `Retain` | `Delete` | Outcome intent using Kubernetes PersistentVolume vocabulary. `Retain` leaves cloud resources in place when the composite is deleted (production networks). |
| `overrides.availabilityZoneNames` | []string | derived | Explicit AZ names, overriding the derived `region`+suffix list. Length must equal `availabilityZones`. |
| `overrides.subnetCidrs` | map (see below) | derived | Per-slot subnet CIDR override. Escape hatch for brownfield adoption and bespoke sizing. |
| `overrides.providerConfigName` | string | `default` | Crossplane `ProviderConfig` for account/credential selection. |

### How subnets are allocated

You normally never specify a CIDR. For a parent block `/P`, the composition
carves fixed-size, pre-reserved slots:

- **Public** subnets are `/(P+6)` (a `/22` for a `/16`), placed low in the range.
- **Private** subnets are `/(P+3)` (a `/19` for a `/16`), placed above them.
- One subnet of each active tier per AZ. Offsets are constants of the parent
  block — independent of AZ count and strategy — so adding an AZ or switching
  strategy only *adds* subnets from reserved slots and never renumbers existing
  ones.

For the default `10.0.0.0/16` across three AZs:

| AZ | public (`/22`) | private (`/19`) |
| --- | --- | --- |
| a | `10.0.0.0/22` | `10.0.32.0/19` |
| b | `10.0.4.0/22` | `10.0.64.0/19` |
| c | `10.0.8.0/22` | `10.0.96.0/19` |

### Manual CIDR overrides (escape hatch)

When you must control the addresses — matching an existing VPC for brownfield
adoption, bespoke sizing, or an organizational IPAM plan — set
`overrides.subnetCidrs`. It is a **map keyed by AZ name** (the same names that
appear in `status.zones[].name`), each with an optional `public` and/or `private`
CIDR:

```yaml
spec:
  parameters:
    region: us-west-2
    availabilityZones: 2
    cidrBlock: "10.0.0.0/16"
    overrides:
      subnetCidrs:
        us-west-2a:
          public: "10.0.0.0/24"
          private: "10.0.10.0/23"
        us-west-2b:
          private: "10.0.20.0/23"   # 2b public omitted -> computed reserved slot
```

The override is **per-slot and partial**: each `(AZ, tier)` you specify takes your
explicit CIDR; every slot you leave out keeps its computed reserved-slot address.
It changes only the *address* of a subnet — the one-public-and-one-private-per-AZ
structure, resource naming, NAT placement, route tables, and the status contract
are all unchanged.

Each override CIDR must fall within `cidrBlock` (the composition asserts this and
fails fast with a clear message). Overlap and alignment between subnets are **not**
checked in the composition — AWS rejects overlapping or misaligned ranges
authoritatively at apply time, so a bad set surfaces as a subnet
`InvalidSubnet.Conflict` on the managed resource.

### Status — the inter-domain contract

Status is structured **by availability zone** so sibling composites (Compute,
DataStore, Ingress) consume AZ-aligned placement data directly rather than
re-deriving alignment from array positions:

```yaml
status:
  networkId: vpc-...          # cloud network identifier
  securityGroupId: sg-...     # the network's default security group
  cidrBlock: 10.0.0.0/16
  zones:
    - name: us-west-2a
      publicSubnetId: subnet-...
      privateSubnetId: subnet-...
      natGatewayId: nat-...
```

## Examples

See [/examples/networks](/examples/networks):

- [`minimal-network.yaml`](/examples/networks/minimal-network.yaml) — region only; everything else defaulted.
- [`production-network.yaml`](/examples/networks/production-network.yaml) — `public-private`, per-AZ NAT, `Retain` reclaim policy.
- [`private-network.yaml`](/examples/networks/private-network.yaml) — `private-only` with no egress, intended to pair with VPC endpoints.
- [`manual-network.yaml`](/examples/networks/manual-network.yaml) — every subnet CIDR set explicitly via `overrides.subnetCidrs`.
- [`fallback-network.yaml`](/examples/networks/fallback-network.yaml) — one slot overridden, the rest left to the computed layout.

## Deployment

- Run `up project run`, or
- Install the Configuration from the [Upbound Marketplace](https://marketplace.upbound.io/configurations/upbound/configuration-aws-network).

## Managed Resource Activation Policy

This configuration includes a `ManagedResourceActivationPolicy` (MRAP) that
activates only the CRDs it needs from dependent providers. If you run Crossplane
without a default activation policy, this keeps the control plane lean by not
activating unused CRDs.

```bash
kubectl get managedresourceactivationpolicy configuration-aws-network -o yaml
```

## Testing

```bash
# Render a composition locally
up composition render --xrd=apis/networks/definition.yaml \
  apis/networks/composition.yaml examples/networks/minimal-network.yaml

# Run all composition tests
up test run tests/*

# Run end-to-end tests (provisions real cloud resources)
up test run tests/* --e2e
```

Composition tests:

- [`tests/test-network`](/tests/test-network) — the computed reserved-slot layout.
- [`tests/test-network-status`](/tests/test-network-status) — spec-derived status shape.
- [`tests/test-network-overrides`](/tests/test-network-overrides) — a fully manual CIDR override.
- [`tests/test-network-fallback`](/tests/test-network-fallback) — a partial override, proving unset slots fall back to computed CIDRs.
- [`tests/e2etest-network`](/tests/e2etest-network) — end-to-end against a live control plane.

## Next steps

This repository is a foundation. To extend it:

1. Add new API definitions in this same repo.
2. Edit the existing `Network` API to fit your needs.

To learn more about building APIs for managed control planes, see
[Upbound's docs](https://docs.upbound.io/).
