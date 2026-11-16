# AWS Terraform rules

Each rule has a short reason. **[G]** = from the AWS Prescriptive Guidance "Terraform AWS
Provider best practices". **[M]** = seen in the `terraform-aws-modules` repositories.
**[F]** = a field lesson: the sources do not cover it, and it caused a real incident.

Rules are numbered so a review can cite them ("breaks S4").

## L — Layout

- **L1. Standard files.** `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`,
  `locals.tf`, `README.md`. Root configs add `providers.tf`, `backend.tf` and
  `.terraform.lock.hcl`. *Every reader and agent finds things in the same place.* [G][M]
- **L2. Split by purpose, not by service.** Keep resources in `main.tf` until it is hard to
  review. Then split by purpose (`iam.tf`). *A file per AWS service makes a reader open five
  files to follow one feature.* [G]
- **L3. Data sources sit next to their user.** Move them to `data.tf` only when there are
  many. [G]
- **L4. Nested modules in `modules/<name>/`**, called with `./modules/<name>`. The root wires
  them together. Nested modules do not call each other several levels deep. [G]
- **L5. Examples in `examples/<name>/`**, each runnable, with a README. The `source` is the
  address a caller would copy (registry or Git), not `../../`. *People copy examples.* [G]
- **L6. Environments.** Shared values in `terraform.tfvars`. Per-environment values in
  `envs/<env>/terraform.tfvars`. No secrets in any committed `.tfvars`. [G]
- **L7. Scripts.** A script Terraform runs (`external`, `local-exec`) goes in `scripts/`. A
  script people run by hand goes in `helpers/` and is documented. Prefer resources:
  *Terraform does not track what a script changes.* [G]
- **L8. Registry-ready.** Repo name `terraform-aws-<name>`, files at the root, semver tags,
  even if you never publish. [G][M]

## B — Module boundaries

- **B1. A module names a capability**: a network baseline, a data tier, an app service.
  *Each module adds an interface to keep, versions to manage, and a place to look during an
  incident.* [G]
- **B2. Do not wrap a single resource.** If the best name is the resource type
  (`s3-bucket`), use the resource, or design around its purpose (`log-archive`). [G]
- **B3. Keep nesting flat.** One or two levels at most. [G]
- **B4. No `provider` blocks in a reusable module.** It declares `required_providers` only.
  For multi-region, use the per-resource `region` argument (AWS provider 6) or accept
  aliased providers through `configuration_aliases`. [G][M]
- **B5. A `create` flag** (`count = var.create ? 1 : 0`) on every resource and data source
  lets a caller switch the module off. Outputs read `try(aws_x.this[0].id, null)`. [M]
- **B6. Only one switch removes resources.** Do not AND other inputs into `create`. Every
  input whose change destroys resources says so in its description. [F]

## I — Interface (variables and outputs)

- **I1. Every variable has a `type` and a `description`.** The description is the docs.
  tflint enforces both. [G][M]
- **I2. Required means no default** plus `nullable = false`. Leave out a default when the
  right value depends on the environment (`vpc_id`, `account_id`). [G]
- **I3. Expose an input only for a real reason.** You can add an optional variable later.
  Removing one breaks every caller. A repeated literal is a `local`. [G]
- **I4. Typed objects, not `any`.** Use `object({...})` with `optional(type, default)`.
  *Bad input fails at plan, with a message.* [M]
- **I5. Limits in `validation` blocks**, not only in the description. If the description
  says "0 to 900", the code checks 0 to 900. [F]
- **I6. Cross-input rules in `precondition` blocks**, with an error message that says what
  to set. [G][M]
- **I7. Names.** snake_case. Units in numeric names (`ram_size_gib`, `retention_days`):
  binary units (GiB) for storage, decimal for the rest. Positive booleans
  (`enable_public_access`, not `disable_private`). Singular. Do not repeat the resource type
  in the resource name. The single resource of a type is `this` or `main`. [G][M]
- **I8. Empty string or empty list as a default** only when the AWS API accepts empty. [G]
- **I9. Outputs come from resource attributes**, not from `var.*`. *An output from a
  resource gives the caller a dependency, so Terraform creates the resource first.* At least
  one output per resource. [G]
- **I10. Static outputs to break a cycle** (an ARN built from name, region and account) are
  the one exception to I9. Name them `*_static` and say why. [M]
- **I11. Sensitive outputs** are marked `sensitive = true`. Prefer `ephemeral = true` outputs
  to pass a secret between modules (Terraform >= 1.10). [G]

## R — Resources

- **R1. `for_each` with stable keys** for any collection. `count` only for 0-or-1. *With
  `count`, removing a middle item moves every later item to a new address and recreates
  it.* [F]
- **R2. Attachment resources, not inline blocks.** One `aws_vpc_security_group_ingress_rule`
  or `_egress_rule` per rule (not `ingress {}` blocks, not `aws_security_group_rule`).
  `aws_iam_role_policy_attachment`, not `managed_policy_arns`. Separate `aws_s3_bucket_*`
  resources, not the deprecated `aws_s3_bucket` arguments. *Two owners of one object
  overwrite each other and show a diff on every plan.* [G]
- **R3. IAM policies as `aws_iam_policy_document` data sources**, not inline
  `jsonencode`. *Typed, mergeable, clean diffs.* [M]
- **R4. Tags.** Shared tags (`Environment`, `Owner`, `CostCenter`, `AppId`, `Project`) in
  the provider `default_tags`. Only `Name` on each resource. `aws_autoscaling_group` does
  not get default tags: read `data.aws_default_tags` and pass them in a `dynamic "tag"`
  block with `propagate_at_launch = true`. [G]
- **R5. Lifecycle.** `create_before_destroy` for things referenced by others (launch
  templates, certificates, security groups). `ignore_changes` only with a comment that
  names who else changes the attribute. `prevent_destroy` on stateful resources in root
  configs. [M][F]
- **R6. No floating versions at plan time.** Do not default to "most recent" add-on, AMI or
  engine versions. Pin them in the root and upgrade on purpose. *A plan that changes on its
  own is drift you created.* [F]
- **R7. Watch defaults that churn.** For example `trigger_on_package_timestamp = false` in
  `terraform-aws-modules/lambda`. Its default plans a new package on every run. [G]

## S — Security

- **S1. Safe defaults in modules.** `deletion_protection = true`, final snapshot on,
  `storage_encrypted = true`, S3 Block Public Access on, deny non-TLS, VPC flow logs on,
  public endpoints off. A public endpoint needs an explicit CIDR list, never a default of
  `0.0.0.0/0`. The caller opts out. [F]
- **S2. Least-privilege egress.** Scope egress to what the workload needs (for example the
  VPC endpoints' security group), not `0.0.0.0/0`. Scanners rate open egress as critical. [G]
- **S3. Secrets never reach the plan or state.** In order of preference: [G]
  1. Service-managed: RDS/Aurora `manage_master_user_password = true`.
  2. `ephemeral "aws_secretsmanager_secret_version"` (or `ephemeral "random_password"`)
     into a write-only argument: `password_wo`, `secret_string_wo`, `value_wo`, with a
     `*_wo_version` that you increase to rotate.
  3. Never the `aws_secretsmanager_secret_version` **data source** for a value: it stores the
     value in state. `sensitive = true` hides output only. The value is still in state.
- **S4. Wrong-account guard.** `allowed_account_ids` in every `provider "aws"` block. If one
  config must work in many accounts, use `forbidden_account_ids` for production. [G]
- **S5. No credentials in code.** No `access_key`, no `profile` in shared provider blocks.
  People use `aws sso login` or `aws login` with a named profile. The provider assumes the
  Terraform role with a `session_name`, so CloudTrail shows who ran it. [G]
- **S6. CI uses OIDC.** The trust policy checks `aud`, `sub` (repo and environment) and `ref`
  (branch). One read-only role plans. A separate role applies, only from `main` behind a
  protected environment. [G]
- **S7. Validate IAM in the pipeline.** `aws accessanalyzer validate-policy` on each
  policy document. Fail on security warnings. `check-no-new-access` for changed policies. [G]
- **S8. Static scan in the gate.** `trivy config` (or checkov) and tflint with the AWS
  ruleset. A suppression has a reason and an expiry date. [G]
- **S9. Policy as code for org rules** (required tags, encryption, approved module
  sources, allowed instance types). OPA, Sentinel or Terraform policy. Terraform policy is
  beta: its CLI `plan -policies` exits 0 on a deny, so fail on `DenyResult` in the JSON. [G]

## T — State and backend

- **T1. S3 backend with native locking.** `use_lockfile = true`, `required_version >=
  1.11`. DynamoDB locking is deprecated. To migrate, set both, run `init -reconfigure`, and
  remove `dynamodb_table` when every runner is on >= 1.11. [G]
- **T2. Encrypt with a customer KMS key.** `encrypt = true` and `kms_key_id`. Without
  `encrypt`, the backend ignores `kms_key_id`. Bucket Key on. [G]
- **T3. State bucket controls.** Versioning on. AWS Backup. Block Public Access. Object
  Ownership "Bucket owner enforced". A bucket policy that denies `s3:*` when
  `aws:SecureTransport` is false. [G]
- **T4. One backend per environment**, ideally one account per environment. Do not use
  workspaces to separate prod from dev. [G]
- **T5. Least privilege on state.** The role gets `s3:ListBucket` (with an `s3:prefix`
  condition), Get/Put on its key, Get/Put/Delete on `<key>.tflock`, and the KMS key. A plan
  role needs the lock permissions too, but not Put on the state key. [G]
- **T6. Audit state.** CloudTrail data events on the state bucket only. An EventBridge rule
  alerts when anyone other than the pipeline role deletes a `.tflock` object (a
  force-unlock). [G]
- **T7. Prod state is read-only for people.** Only the pipeline and break-glass roles
  write. [G]

## C — Changes and refactors

- **C1. Code, not commands.** `moved {}` to rename or move into a module. `removed {
  from = ...; lifecycle { destroy = false } }` to stop managing without deleting. `import {}`
  (with `plan -generate-config-out`) to adopt. *The PR shows it and the plan proves it.* [G][M]
- **C2. Keep migrations.** Put `moved` blocks in `migrations.tf` with the version range
  they serve. Keep them for at least one major version. [M]
- **C3. Breaking changes** in a reusable module: a major version, a `docs/UPGRADE-N.md`
  that lists every removed input and changed default, and `moved` blocks so the upgrade
  does not recreate anything. [M]
- **C4. Apply only the reviewed plan of the merged commit.** Never apply from a branch or a
  checkout older than `main`. *An old branch carries old config and writes it back over
  newer changes, secrets included.* [F]

## V — Versions and dependencies

- **V1. Reusable module:** `required_version = ">= x"`, providers `>= x`. No upper bound. No
  lock file. [G][M]
- **V2. Root config:** providers `~> 6.0` (or tighter). Commit `.terraform.lock.hcl`. Add
  hashes for every platform: `terraform providers lock -platform=linux_amd64
  -platform=linux_arm64 -platform=darwin_arm64`. [G]
- **V3. CI runs `terraform init -lockfile=readonly`**, so CI never changes dependencies. [G]
- **V4. Modules pinned.** Registry: an exact `version = "8.12.0"`. Git: `?ref=<full SHA>`
  with the release in a comment. *The lock file covers providers, not modules.* [G]
- **V5. Community modules.** `terraform-aws-modules` is not verified. AWS-published verified
  modules are in `aws-ia`. Review maintainers, releases, open issues and the module's own
  dependencies before you adopt one. Override with inputs. Fork only to contribute back. [G]
- **V6. Upgrades are PRs.** Renovate or Dependabot opens them. The gate and a plan run on
  each. Check that the lock file has every platform's hashes. [G]
- **V7. Major provider upgrades in steps.** Latest minor of the current major, clear every
  deprecation warning, bump the constraint, `init -upgrade`, plan, non-prod first. [G]
- **V8. CI actions pinned by commit SHA**, with the tag in a comment. *The pipeline holds the
  apply role.* [F]

## Q — Quality gate and tests

- **Q1. One gate command.** `fmt -check -recursive`, `init -backend=false
  -lockfile=readonly`, `validate`, `tflint` (with the `aws` ruleset and the `terraform`
  rules), `trivy config`, `terraform test -filter=tests/unit.tftest.hcl`. Same command
  locally, in pre-commit and in CI. [G][M]
- **Q2. Unit tests with `mock_provider "aws" {}`** and `command = plan`. Test every
  validation (`expect_failures = [var.x]`), precondition and computed local. Fast, free, no
  credentials. Use `mock_data` / `mock_resource` for values the code reads. Terraform
  >= 1.17 adds `mock_ephemeral` for secrets. [G]
- **Q3. Integration tests** in `tests/integration.tftest.hcl`, `command = apply`, in a
  dedicated test account (`allowed_account_ids` set, default tags that mark test
  resources). Run on a schedule or before a release, not on every commit. [G]
- **Q4. `check` blocks** for ongoing health. They warn and do not stop the run. They must
  read inputs, not resources created in the same run, or plan-mode tests fail. [G]
- **Q5. Test on the minimum and maximum Terraform version** a reusable module claims. [M]
- **Q6. Docs generated.** `terraform-docs` writes the inputs and outputs tables. [G][M]
- **Q7. Drift is a scheduled job.** `plan -detailed-exitcode -out=plan.out`: 0 = clean,
  1 = error, 2 = changes. On 2, publish `terraform show plan.out`. Do not use
  `-refresh-only` exit codes or `-minimal-refresh` for drift. [G]
- **Q8. Commits.** Conventional commit titles (`feat:`, `fix:`) let a release tool set the
  version and write the changelog. [M]
