# Outputs are maps keyed like the input, so callers look up an archive by name (rule F5).

output "bucket_arns" {
  description = "Bucket ARN per archive key."
  value       = { for key, archive in module.archive : key => archive.bucket_arn }
}

output "bucket_ids" {
  description = "Bucket name per archive key."
  value       = { for key, archive in module.archive : key => archive.bucket_id }
}
