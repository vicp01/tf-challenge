# Region-specific ELB logging service account
data "aws_elb_service_account" "this" {}

# Suffix for unique bucket name
resource "random_id" "alb_logs_suffix" {
  count       = var.enable_alb_logs ? 1 : 0
  byte_length = 3
}

# The logs bucket
resource "aws_s3_bucket" "alb_logs" {
  count  = var.enable_alb_logs ? 1 : 0
  bucket = "sre-alb-logs-${random_id.alb_logs_suffix[0].hex}"
}

# Versioning
resource "aws_s3_bucket_versioning" "alb_logs" {
  count  = var.enable_alb_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption (SSE-S3)
resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  count  = var.enable_alb_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "alb_logs" {
  count  = var.enable_alb_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy that lets ALB deliver logs (PutObject) into this bucket
data "aws_iam_policy_document" "alb_logs" {
  count = var.enable_alb_logs ? 1 : 0

  statement {
    sid     = "AllowELBLogDelivery"
    effect  = "Allow"
    actions = ["s3:PutObject"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.this.arn]
    }

    resources = [
      "${aws_s3_bucket.alb_logs[0].arn}/*"
    ]

    # Require bucket-owner-full-control ACL from ELB deliveriess
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  count  = var.enable_alb_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id
  policy = data.aws_iam_policy_document.alb_logs[0].json
}
