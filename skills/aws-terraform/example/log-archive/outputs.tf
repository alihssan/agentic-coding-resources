# Outputs come from resources, so callers get a dependency (rule I9).

output "bucket_id" {
  description = "Name of the log bucket."
  value       = try(aws_s3_bucket.this[0].id, null)
}

output "bucket_arn" {
  description = "ARN of the log bucket."
  value       = try(aws_s3_bucket.this[0].arn, null)
}

output "bucket_policy_id" {
  description = "Bucket the TLS-only policy is attached to. Depend on this before writing logs."
  value       = try(aws_s3_bucket_policy.this[0].id, null)
}
