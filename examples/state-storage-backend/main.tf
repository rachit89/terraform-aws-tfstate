locals {
  aws_region                              = "us-east-1"
  aws_account_id                          = "767398031518" # AWS Account ID
  environment                             = "prod"
  s3_bucket_logging                       = "true"
  s3_bucket_name                          = "prod-tfstate"
  s3_bucket_force_destroy                 = true
  s3_bucket_versioning_enabled            = true
  cloudwatch_logging_enabled              = true
  cloudwatch_log_bucket_lifecycle_enabled = true
  cloudwatch_log_group_skip_destroy       = false
  cloudtrail_data_resources_enable        = true
  cloudtrail_s3_key_prefix                = "logs"
  additional_tags = {
    Owner      = "organization_name"
    Expires    = "Never"
    Department = "Engineering"
  }
  # Define the lifecycle rules
  s3_bucket_lifecycle_rules = [
    {
      id      = "log"
      enabled = true
      transitions = [
        {
          days          = 90
          storage_class = "ONEZONE_IA"
        },
        {
          days          = 180
          storage_class = "GLACIER"
        }
      ]
    }
  ]
}

module "backend" {
  source                            = "../.."
  aws_region                        = local.aws_region
  aws_account_id                    = local.aws_account_id
  s3_bucket_logging                 = local.s3_bucket_logging
  s3_bucket_name                    = local.s3_bucket_name ############unique global s3 bucket name
  environment                       = local.environment
  s3_bucket_force_destroy           = local.s3_bucket_force_destroy
  s3_bucket_versioning_enabled      = local.s3_bucket_versioning_enabled
  cloudwatch_logging_enabled        = local.cloudwatch_logging_enabled
  cloudwatch_log_group_skip_destroy = local.cloudwatch_log_group_skip_destroy
  cloudwatch_log_retention_in_days  = "90"
  s3_log_bucket_lifecycle_enabled   = local.cloudwatch_log_bucket_lifecycle_enabled
  s3_ia_retention_in_days           = "90"
  s3_galcier_retention_in_days      = "180"
  # s3_bucket_lifecycle_rules         = local.s3_bucket_lifecycle_rules
  cloudtrail_data_resources_enable = local.cloudtrail_data_resources_enable
  cloudtrail_s3_key_prefix         = local.cloudtrail_s3_key_prefix
  additional_tags                  = local.additional_tags
}