# A capability, not a wrapper (rule B2): a private, encrypted, TLS-only bucket that keeps
# logs for a fixed time. Callers choose a name, a key and a retention. Nothing else.

data "aws_iam_policy_document" "tls_only" {
  count = var.create ? 1 : 0

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.this[0].arn, "${aws_s3_bucket.this[0].arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket" "this" {
  count = var.create ? 1 : 0

  bucket        = var.name
  force_destroy = var.enable_force_destroy

  tags = merge(var.tags, { Name = var.name })

  lifecycle {
    precondition {
      condition     = var.transition_to_glacier_days == null || try(var.transition_to_glacier_days < var.retention_days, false)
      error_message = "transition_to_glacier_days must be less than retention_days, or null."
    }
  }
}

# Attachment resources, one owner per setting (rule R2).
resource "aws_s3_bucket_public_access_block" "this" {
  count = var.create ? 1 : 0

  bucket                  = aws_s3_bucket.this[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "this" {
  count = var.create ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "this" {
  count = var.create ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count = var.create ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.create ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    filter {}

    dynamic "transition" {
      for_each = var.transition_to_glacier_days == null ? [] : [var.transition_to_glacier_days]

      content {
        days          = transition.value
        storage_class = "GLACIER"
      }
    }

    expiration {
      days = var.retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

resource "aws_s3_bucket_policy" "this" {
  count = var.create ? 1 : 0

  bucket = aws_s3_bucket.this[0].id
  policy = data.aws_iam_policy_document.tls_only[0].json

  # The public access block must exist first, or a policy change can race it.
  depends_on = [aws_s3_bucket_public_access_block.this]
}
