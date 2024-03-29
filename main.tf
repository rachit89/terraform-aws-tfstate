resource "aws_iam_role" "iam_role" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = merge(
    { "Name" = format("%s-%s", var.environment, var.s3_bucket_name) },
    var.additional_tags,
  )
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.iam_role.arn]
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${format("%s-%s", var.s3_bucket_name, var.aws_account_id)}",
    ]
  }
}

resource "aws_s3_bucket_object_lock_configuration" "object_lock_tfstate" {
  count  = var.s3_bucket_enable_object_lock_tfstate ? 1 : 0
  bucket = module.s3_bucket.s3_bucket_id

  rule {
    default_retention {
      mode  = var.s3_bucket_object_lock_mode_tfstate
      
      // Use days if provided, otherwise use years converted to days
      days  = var.s3_bucket_object_lock_days_tfstate > 0 ? var.s3_bucket_object_lock_days_tfstate : null
      years = var.s3_bucket_object_lock_years_tfstate > 0 ? var.s3_bucket_object_lock_years_tfstate : null
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_bucket_lifecycle_rules_tfstate" {
  bucket = module.s3_bucket.s3_bucket_id
   count  = var.s3_bucket_lifecycle_rules_tfstate_enabled ? 1 : 0
  
  dynamic "rule" {
    for_each = var.s3_bucket_lifecycle_rules_tfstate

    content {
      id = rule.value.id

      expiration {
        days = rule.value.expiration_days
      }

      filter {
        prefix = rule.value.filter_prefix
      }

      status = rule.value.status

      dynamic "transition" {
        for_each = rule.value.transitions

        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }
    }
  }
}
module "s3_bucket" {
  source                                = "terraform-aws-modules/s3-bucket/aws"
  version                               = "4.1.0"
  bucket                                = format("%s-%s", var.s3_bucket_name, var.aws_account_id)
  force_destroy                         = var.s3_bucket_force_destroy
  attach_policy                         = var.s3_bucket_attach_policy
  policy                                = data.aws_iam_policy_document.bucket_policy.json
  attach_deny_insecure_transport_policy = var.s3_bucket_attach_deny_insecure_transport_policy
  versioning = {
    enabled = var.s3_bucket_versioning_enabled
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.kms_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  logging = var.s3_bucket_logging ? {
    target_bucket = module.log_bucket[0].s3_bucket_id
    target_prefix = "log/"
  } : {}

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = var.s3_bucket_block_public_acls
  block_public_policy     = var.s3_bucket_block_public_policy
  ignore_public_acls      = var.s3_bucket_ignore_public_acls
  restrict_public_buckets = var.s3_bucket_restrict_public_buckets

  # S3 Bucket Ownership Controls
  control_object_ownership = var.s3_bucket_control_object_ownership
  object_ownership         = var.s3_bucket_object_ownership
}

resource "aws_dynamodb_table" "dynamodb_table" {
  name           = format("%s-%s-%s", var.s3_bucket_name, "lock-dynamodb", var.aws_account_id)
  hash_key       = var.dynamodb_table_attribute_name
  read_capacity  = var.dynamodb_read_capacity
  write_capacity = var.dynamodb_write_capacity

  attribute {
    name = var.dynamodb_table_attribute_name
    type = var.dynamodb_table_attribute_type
  }

  tags = merge(
    { "Name" = format("%s-%s-%s", var.s3_bucket_name, "lock-dynamodb", var.aws_account_id) },
    var.additional_tags,
  )
}

resource "aws_kms_key" "kms_key" {
  description             = var.kms_key_description
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = var.kms_key_rotation_enabled
  tags = merge(
    { "Name" = format("%s-%s", var.environment, var.s3_bucket_name) },
    var.additional_tags,
  )
}

resource "aws_kms_alias" "custom_alias" {
  count         = var.s3_bucket_logging ? 1 : 0
  name          = "alias/${var.s3_bucket_name}-kms-03"
  target_key_id = aws_kms_key.kms_key.id
}

data "aws_iam_policy_document" "default" {
  count   = var.s3_bucket_logging ? 1 : 0
  version = "2012-10-17"
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "Allow CloudTrail to encrypt logs"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["kms:GenerateDataKey*"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:aws:cloudtrail:*:${var.aws_account_id}:trail/*"]
    }
  }

  statement {
    sid    = "Allow CloudTrail to describe key"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["kms:DescribeKey"]
    resources = ["*"]
  }

  statement {
    sid    = "Allow principals in the account to decrypt log files"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "kms:Decrypt",
      "kms:ReEncryptFrom",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = ["${var.aws_account_id}"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:aws:cloudtrail:*:${var.aws_account_id}:trail/*"]
    }
  }

  statement {
    sid    = "Allow alias creation during setup"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = ["kms:CreateAlias"]
    resources = ["*"]
  }
}

resource "aws_kms_key_policy" "cloudtrail_key_policy" {
  count  = var.s3_bucket_logging ? 1 : 0
  key_id = aws_kms_key.kms_key.key_id
  policy = data.aws_iam_policy_document.default[0].json
}