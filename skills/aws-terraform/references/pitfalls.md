# Pitfalls seen in real modules

Found in a read of 13 `terraform-aws-modules` repositories (eks, vpc, lambda, rds,
rds-aurora, iam, s3-bucket, security-group, alb, ecs, kms, secrets-manager, sqs) on
2026-11-16. These are among the most used AWS modules. The point is not that they are bad.
The point is that even good modules have these gaps, so check for them when you **use** a
module and avoid them when you **write** one. Rule IDs refer to [`rules.md`](rules.md).

| # | Pitfall | Evidence | What to do |
|---|---|---|---|
| 1 | CI never plans, applies or tests | No `*.tftest.hcl` in any sampled repo. CI runs fmt, validate, tflint and docs only. | Q2, Q3. Do not assume a popular module was ever applied in CI. |
| 2 | No security scanner | No trivy, checkov or tfsec in any workflow. | S8. Scan your root config, which includes the modules it calls. |
| 3 | Unsafe defaults on stateful resources | `deletion_protection` is `false` (rds) or `null` (rds-aurora, eks). VPC flow logs off. S3 deny-non-TLS and latest-TLS policies off. | S1. Set these in your root config explicitly. Never trust the module default. |
| 4 | Latent open endpoint | eks `endpoint_public_access_cidrs` defaults to `0.0.0.0/0`. Turning public access on opens it to the internet. | S1. Always pass the CIDR list when you enable public access. |
| 5 | Lists keyed by `count` | 27 `count = length(...)` sites, including VPC subnets and secondary CIDRs. | R1. Do not remove a middle AZ or subnet from such a list without reading the plan. |
| 6 | Limits only in prose | 110 `validation` blocks for about 3,180 variables. sqs `delay_seconds` says "0 to 900" and checks nothing. | I5. Expect errors at apply time, not plan time. |
| 7 | Versions float at plan time | eks v21 defaults `addons.most_recent = true` and `use_latest_ami_release_version = true`. | R6. Pin add-on and AMI versions in the root. |
| 8 | Default that churns | lambda `trigger_on_package_timestamp = true` plans a new package every run. | R7. Set it to `false`. |
| 9 | Hidden kill switch | A non-technical boolean (default `true`) is ANDed into `create` in security-group, s3-bucket and others. Set to `false`, it plans every resource for destroy. | B6. Read every input that feeds `create`. |
| 10 | Wrong description on a secret input | rds `password_wo` says the value "will be stored in the state file". Write-only values are not stored. | Read the provider docs, not only the module README, for anything about secrets. |
| 11 | Output with no dependency | rds-aurora `cluster_database_name` returns `var.database_name`. A caller can use it before the cluster exists. | I9. Add `depends_on` in the caller, or use a resource output. |
| 12 | Legacy rule resources | eks and vpc still use `aws_security_group_rule` or inline `ingress` blocks. | R2. Do not add your own rules to the same group through a second resource type. |
| 13 | Examples use relative sources | 191 example module blocks use `../../`. | L5. Replace with the registry address and an exact version when you copy one. |
| 14 | No wrong-account guard in examples | No example sets `allowed_account_ids`. | S4. Add it when you copy an example. |
| 15 | CI actions pinned by tag | Third-party actions use tags like `@v1.14.0`. The release job holds a token. | V8. Pin your own pipeline by SHA. |
| 16 | Loose inputs remain | 204 `type = any` variables. | I4. A typo in a map key is silently ignored. Check the plan. |

## Gaps in the AWS guide itself

The guide is the main source for `rules.md`, but it does not cover these. The `[F]` rules
fill them.

- `count` versus `for_each` keys (R1).
- Safe defaults inside reusable modules (S1). It covers them only as policy-as-code checks.
- Applying from a stale branch (C4). Separate backends and approvals do not stop it.
- Pinning the CI actions that hold the apply role (V8).
- Version-specific behaviour ages fast. Several rules name Terraform 1.17 or provider 6.70
  behaviour (refresh-only exit codes, `-policies` exit code). Check them again after an
  upgrade.
