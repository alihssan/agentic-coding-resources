# S3 state, one backend per environment (rule T4). Backend blocks cannot use variables,
# so keep the per-environment values in envs/<env>/backend.hcl and run:
#   terraform init -backend-config=envs/<env>/backend.hcl
#
# envs/prod/backend.hcl:
#   bucket       = "<STATE_BUCKET_IN_PROD_ACCOUNT>"
#   key          = "<STACK>/prod/terraform.tfstate"
#   region       = "<REGION>"
#   kms_key_id   = "arn:aws:kms:<REGION>:<ACCOUNT_ID>:key/<KEY_ID>"
#
# The state bucket itself: versioning on, AWS Backup, Block Public Access, Bucket owner
# enforced, a deny-non-TLS policy, CloudTrail data events, and an alert when anyone but the
# pipeline role deletes a *.tflock object (rules T3, T6).

terraform {
  backend "s3" {
    encrypt      = true # without this, kms_key_id is ignored (rule T2)
    use_lockfile = true # S3 native locking; DynamoDB locking is deprecated (rule T1)
  }
}
