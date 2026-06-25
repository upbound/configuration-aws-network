# AWS Network Configuration

This repository contains an Upbound project, tailored for users establishing their initial control plane with [Upbound](https://cloud.upbound.io). This configuration deploys fully managed AWS network resources.

## Overview

The core components of a custom API in [Upbound Project](https://docs.upbound.io/learn/control-plane-project/) include:

- **CompositeResourceDefinition (XRD):** Defines the API's structure.
- **Composition(s):** Implements the API by orchestrating a set of Crossplane managed resources.
- **Embedded Function(s):** Encapsulates the Composition logic and implementation within a self-contained, reusable unit

In this specific configuration, the AWS Network API contains:

- **a namespaced [Network](/apis/networks/definition.yaml) custom resource type** (`aws.platform.upbound.io/v1alpha1`, Crossplane v2 `Namespaced` scope).
- **Composition of the networking resources:** Configured in [/apis/networks/composition.yaml](/apis/networks/composition.yaml).
- **Embedded Function:** The Composition logic is encapsulated within an [embedded function](/functions/network/main.k).

## The Network API

The Network API is **declarative**: you describe the shape of the network you want, and the composition allocates subnets, gateways, route tables and security groups for you. There is no need to enumerate individual subnets or CIDRs by hand — the only required parameter is `region`.

A minimal network is a single field:

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
| `overrides.providerConfigName` | string | `default` | Crossplane `ProviderConfig` for account/credential selection. |

### Status — the inter-domain contract

Status is structured **by availability zone** so sibling composites (Compute, DataStore, Ingress) can consume AZ-aligned placement data directly rather than re-deriving alignment from array positions:

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

### Examples

See [/examples/networks](/examples/networks) for ready-to-apply Networks:

- [`minimal-network.yaml`](/examples/networks/minimal-network.yaml) — region only; everything else defaulted.
- [`private-network.yaml`](/examples/networks/private-network.yaml) — `private-only` with no egress, intended to pair with VPC endpoints.
- [`production-network.yaml`](/examples/networks/production-network.yaml) — `public-private`, per-AZ NAT, `Retain` reclaim policy.

## Deployment

- Execute `up project run`
- Alternatively, install the Configuration from the [Upbound Marketplace](https://marketplace.upbound.io/configurations/upbound/configuration-aws-network)
- Check [examples](/examples/) for example XR(Composite Resource)

## Managed Resource Activation Policy

This configuration includes a `ManagedResourceActivationPolicy` (MRAP) that enables only the required CRDs from dependent providers. If you're running Crossplane without a default activation policy, this ensures that only the necessary CRDs are activated, reducing resource overhead and improving control plane performance.

To view the MRAP:
```bash
kubectl get managedresourceactivationpolicy configuration-aws-network -o yaml
```

## Testing

The configuration can be tested using:

- `up composition render --xrd=apis/networks/definition.yaml apis/networks/composition.yaml examples/networks/minimal-network.yaml` to render the composition
- `up test run tests/*` to run composition tests in `tests/test-network/`
- `up test run tests/* --e2e` to run end-to-end tests in `tests/e2etest-network`

## Next steps

This repository serves as a foundational step. To enhance your configuration, consider:

1. create new API definitions in this same repo
2. editing the existing API definition to your needs

To learn more about how to build APIs for your managed control planes in Upbound, read the guide on [Upbound's docs](https://docs.upbound.io/).
