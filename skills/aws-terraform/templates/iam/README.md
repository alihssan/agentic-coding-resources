# CI roles for Terraform (rule S6)

Two roles. Never one.

| Role | Trust policy | Can do |
|---|---|---|
| Plan | `github-oidc-trust-plan.json`: any PR of the repo, or `main` | Read every resource Terraform manages. On the state bucket: `s3:ListBucket` (with an `s3:prefix` condition), `s3:GetObject` on the state key, Get/Put/Delete on `<key>.tflock` (plan takes the lock). `kms:Decrypt` on the state key. **No** `s3:PutObject` on the state key. |
| Apply | `github-oidc-trust-apply.json`: only jobs in the protected `<ENVIRONMENT>` GitHub environment, only on `main` | Change the resources this stack manages, and nothing else. Put on the state key, Get/Put/Delete on the lock, `kms:Encrypt`/`Decrypt`/`GenerateDataKey`. |

- The `ref` condition on the apply role is what IAM Access Analyzer recommends when `sub`
  names an environment. Without it, a job in that environment on another branch could apply.
- In the GitHub environment, set required reviewers and "Deployment branches: main only".
- A pull request from a fork gets no OIDC token for this repo. Plan runs only on branches of
  the repo itself.
- Before you create a role, run `aws accessanalyzer validate-policy` on both documents
  (rule S7). This is a human step. The agent does not create IAM roles.
- Start the apply role's permission policy from IAM Access Analyzer policy generation over a
  test-account CloudTrail, then remove what the stack does not need.
