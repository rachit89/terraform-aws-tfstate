resource "aws_cloudtrail" "s3_cloudtrail" {
  count                         = var.s3_bucket_logging_enabled ? 1 : 0
  name                          = format("%s-%s-s3-trail", var.s3_bucket_name, var.aws_account_id)
  s3_bucket_name                = module.log_bucket[0].s3_bucket_id
  s3_key_prefix                 = var.cloudtrail_s3_key_prefix
  include_global_service_events = var.s3_bucket_include_global_service_events
  enable_logging                = var.cloudtrail_logging_enabled
  enable_log_file_validation    = var.cloudtrail_enable_log_file_validation
  cloud_watch_logs_role_arn     = var.cloudwatch_logging_enabled ? aws_iam_role.s3_cloudtrail_cloudwatch_role[0].arn : null
  cloud_watch_logs_group_arn    = var.cloudwatch_logging_enabled ? "${aws_cloudwatch_log_group.s3_cloudwatch[0].arn}:*" : null
  kms_key_id                    = aws_kms_key.kms_key.arn

  event_selector {
    read_write_type           = var.logging_read_write_type
    include_management_events = var.s3_bucket_include_management_events

    dynamic "data_resource" {
      for_each = var.cloudtrail_data_resources_enable ? [1] : []
      content {
        type   = "AWS::S3::Object"
        values = ["arn:aws:s3"]
      }
    }

    dynamic "data_resource" {
      for_each = var.cloudtrail_data_resources_enable ? [1] : []
      content {
        type   = "AWS::Lambda::Function"
        values = ["arn:aws:lambda"]
      }
    }
  }

  tags = merge(
    { "Name" = format("%s-%s-s3", var.s3_bucket_name, var.aws_account_id) },
    var.additional_aws_tags,
  )
}

resource "aws_cloudwatch_log_group" "s3_cloudwatch" {
  count             = var.s3_bucket_logging_enabled && var.cloudwatch_logging_enabled ? 1 : 0
  name              = format("%s-%s-s3", var.s3_bucket_name, var.aws_account_id)
  retention_in_days = var.cloudwatch_log_retention_in_days
  kms_key_id        = aws_kms_key.kms_key.arn

  tags = merge(
    { "Name" = format("%s-%s-s3", var.s3_bucket_name, var.aws_account_id) },
    var.additional_aws_tags,
  )
}

resource "aws_iam_role" "s3_cloudtrail_cloudwatch_role" {
  count              = var.s3_bucket_logging_enabled && var.cloudwatch_logging_enabled ? 1 : 0
  name               = format("%s-cloudtrail-cloudwatch-s3", var.s3_bucket_name)
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume_role[0].json
  tags = merge(
    { "Name" = format("%s-cloudtrail-cloudwatch-s3", var.s3_bucket_name) },
    var.additional_aws_tags,
  )
}

data "aws_iam_policy_document" "cloudtrail_assume_role" {
  count = var.s3_bucket_logging_enabled ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "s3_cloudtrail_cloudwatch_policy" {
  count = var.s3_bucket_logging_enabled && var.cloudwatch_logging_enabled ? 1 : 0
  name  = format("%s-cloudtrail-cloudwatch-s3", var.s3_bucket_name)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AWSCloudTrailCreateLogStream2014110"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream"]
        Resource = ["arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:${var.s3_bucket_name}-${var.aws_account_id}-s3:*"]
      },
      {
        Sid      = "AWSCloudTrailPutLogEvents20141101"
        Effect   = "Allow"
        Action   = ["logs:PutLogEvents"]
        Resource = ["arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:${var.s3_bucket_name}-${var.aws_account_id}-s3:*"]
      },
    ]
  })
  tags = merge(
    { "Name" = format("%s-cloudtrail-cloudwatch-s3", var.s3_bucket_name) },
    var.additional_aws_tags,
  )
}

resource "aws_iam_role_policy_attachment" "s3_cloudtrail_policy_attachment" {
  count      = var.s3_bucket_logging_enabled && var.cloudwatch_logging_enabled ? 1 : 0
  role       = aws_iam_role.s3_cloudtrail_cloudwatch_role[0].name
  policy_arn = aws_iam_policy.s3_cloudtrail_cloudwatch_policy[0].arn
}

module "log_bucket" {
  count                                 = var.s3_bucket_logging_enabled ? 1 : 0
  source                                = "terraform-aws-modules/s3-bucket/aws"
  version                               = "4.1.0"
  bucket                                = format("%s-%s-log-bucket", var.s3_bucket_name, var.aws_account_id)
  force_destroy                         = var.s3_bucket_force_destroy
  attach_elb_log_delivery_policy        = var.s3_bucket_attach_elb_log_delivery_policy
  attach_lb_log_delivery_policy         = var.s3_bucket_attach_lb_log_delivery_policy
  attach_deny_insecure_transport_policy = var.s3_bucket_attach_deny_insecure_transport_policy
  versioning = {
    enabled = var.s3_bucket_versioning_enabled
  }
  # S3 bucket-level Public Access Block configuration
  block_public_acls       = var.s3_bucket_block_public_acls
  block_public_policy     = var.s3_bucket_block_public_policy
  ignore_public_acls      = var.s3_bucket_ignore_public_acls
  restrict_public_buckets = var.s3_bucket_restrict_public_buckets

  attach_policy = var.s3_bucket_attach_policy
  policy        = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck20150319",
            "Effect": "Allow",
            "Principal": {"Service": "cloudtrail.amazonaws.com"},
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${var.s3_bucket_name}-${var.aws_account_id}-log-bucket",
            "Condition": {
                "StringEquals": {
                    "aws:SourceArn": "arn:aws:cloudtrail:${var.aws_region}:${var.aws_account_id}:trail/${var.s3_bucket_name}-${var.aws_account_id}-s3-trail"
                }
            }
        },
        {
            "Sid": "AWSCloudTrailWrite20150319",
            "Effect": "Allow",
            "Principal": {"Service": "cloudtrail.amazonaws.com"},
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${var.s3_bucket_name}-${var.aws_account_id}-log-bucket/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control",
                    "aws:SourceArn": "arn:aws:cloudtrail:${var.aws_region}:${var.aws_account_id}:trail/${var.s3_bucket_name}-${var.aws_account_id}-s3-trail"
                }
            }
        }
    ]
}
POLICY
}
