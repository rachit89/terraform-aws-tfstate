variable "additional_tags" {
  description = "Additional tags to be applied to AWS resources"
  type        = map(string)
  default     = {
    Owner      = ""
    Expires    = ""
    Department = ""
  }
}

variable "aws_region" {
  description = "Name of the AWS region where S3 bucket is to be created."
  default     = ""
  type        = string
}

variable "aws_account_id" {
  description = "Account ID of the AWS Account."
  default     = ""
  type        = string
}

variable "kms_deletion_window_in_days" {
  description = " Waiting period (in days) before the KMS key can be deleted after it's scheduled for deletion."
  default     = 10
  type        = number
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket to be created."
  default     = ""
  type        = string
}

variable "s3_bucket_force_destroy" {
  description = "Whether or not to delete all objects from the bucket to allow for destruction of the bucket without error."
  default     = false
  type        = bool
}

variable "s3_bucket_attach_policy" {
  description = "Whether or not to attach AWS IAM policy to the S3 Bucket."
  default     = true
  type        = bool
}

variable "s3_bucket_attach_deny_insecure_transport_policy" {
  description = "Whether to attach a policy that denies requests made over insecure transport protocols to the S3 bucket."
  default     = true
  type        = bool
}


variable "s3_bucket_versioning_enabled" {
  description = "Whether or not to enable versioning for the S3 bucket, which allows multiple versions of an object to be stored in the same bucket."
  default     = false
  type        = bool
}

variable "s3_bucket_logging" {
  description = "Configuration for S3 bucket access logging."
  default     = true
  type        = bool
}

variable "s3_bucket_block_public_acls" {
  description = "Whether Amazon S3 should block public ACLs for this bucket."
  default     = true
  type        = bool
}

variable "s3_bucket_block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for this bucket.	"
  default     = true
  type        = bool
}

variable "s3_bucket_ignore_public_acls" {
  description = "Whether Amazon S3 should ignore public ACLs for this bucket."
  default     = true
  type        = bool
}

variable "s3_bucket_restrict_public_buckets" {
  description = "Whether Amazon S3 should restrict public bucket policies for this bucket."
  default     = true
  type        = bool
}

variable "s3_bucket_control_object_ownership" {
  description = "Whether to manage S3 Bucket Ownership Controls on this bucket."
  default     = true
  type        = bool
}

variable "s3_bucket_object_ownership" {
  description = "Object ownership. Valid values: BucketOwnerEnforced, BucketOwnerPreferred or ObjectWriter."
  default     = "BucketOwnerPreferred"
  type        = string
}

variable "environment" {
  description = "Specify the type of environment(dev, demo, prod) in which the S3 bucket will be created. "
  default     = ""
  type        = string
}

variable "dynamodb_read_capacity" {
  description = "Number of read units for dynamodb table."
  default     = 20
  type        = number
}

variable "dynamodb_write_capacity" {
  description = "Number of write units for dynamodb table."
  default     = 20
  type        = number
}

variable "dynamodb_table_attribute_name" {
  description = "The name of the attribute in the DynamoDB table."
  default     = "LockID"
  type        = string
}

variable "dynamodb_table_attribute_type" {
  description = "The data type of the attribute in the DynamoDB table.Valid values are S (string), N (number), B (binary)."
  default     = "S"
  type        = string
}

variable "cloudwatch_logging_enabled" {
  description = "CloudWatch log group logging should be enabled or disabled."
  default     = true
  type        = bool
}

variable "cloudwatch_log_retention_in_days" {
  description = "Retention period (in days) for CloudWatch log groups."
  default     = 90
  type        = number
}

variable "s3_galcier_retention_in_days" {
  description = "Retention period (in days) for moving S3 log data to Glacier storage."
  default     = 180
  type        = number
}

variable "s3_ia_retention_in_days" {
  description = "Retention period (in days) for moving S3 log data to Infrequent Access storage."
  default     = 90
  type        = number
}

variable "s3_log_bucket_lifecycle_enabled" {
  description = "The S3 bucket's lifecycle rule for log data to be enabled or not."
  default     = true
  type        = bool
}

variable "cloudtrail_logging_enabled" {
  description = "Enables logging for the Cloud trail."
  default     = true
  type        = bool
}

variable "s3_bucket_include_global_service_events" {
  description = "Whether the trail is publishing events from global services such as IAM to the log files."
  default     = true
  type        = bool
}

variable "cloudtrail_enable_log_file_validation" {
  description = "Whether log file integrity validation is enabled."
  default     = true
  type        = bool
}

variable "s3_bucket_include_management_events" {
  description = "Whether to include management events for your trail."
  default     = true
  type        = bool
}

variable "s3_bucket_attach_elb_log_delivery_policy" {
  description = "When set to true, it indicates that an Elastic Load Balancer log delivery policy should be attached to the S3 bucket. This policy configures ELB to deliver access logs to the specified S3 bucket."
  default     = true
  type        = bool
}

variable "s3_bucket_attach_lb_log_delivery_policy" {
  description = "when set to true, it indicates that a Load Balancer log delivery policy should be attached to the S3 bucket. This policy configures the Load Balancer to deliver access logs to the specified S3 bucket."
  default     = true
  type        = bool
}

variable "kms_key_rotation_enabled" {
  description = "Whether automatic key rotation should be enabled for the AWS Key Management Service (KMS) key being created."
  default     = true
  type        = bool
}

variable "logging_read_write_type" {
  description = "Categories of Events for Logging.Valid values are ReadOnly, WriteOnly, All. Default value is All."
  default     = "All"
  type        = string
}

variable "cloudwatch_log_group_skip_destroy" {
  description = "Set to true if do not want the log group to be deleted at destroy time."
  default     = true
  type        = bool
}

variable "kms_key_description" {
  description = "Explaination of resource created under aws_kms_key."
  default     = "This key is used to encrypt bucket objects."
  type        = string
}

variable "cloudtrail_data_resources_enable" {
  description = "Set to true to enable data resources in resource aws_cloudtrail."
  default     = true
  type        = bool
}

variable "cloudtrail_s3_key_prefix" {
  description = "Specify a prefix for the keys of the log files that CloudTrail will create in the designated S3 bucket."
  default     = "logs"
  type        = string
}

variable "s3_bucket_enable_object_lock" {
  description = "Whether to enable object lock"
  type        = bool
  default     = true
}

variable "s3_bucket_object_lock_mode" {
  description = "Default Object Lock retention mode you want to apply to new objects placed in the specified bucket. Valid values: COMPLIANCE, GOVERNANCE."
  type        = string
  default     = "GOVERNANCE"
}

variable "s3_bucket_object_lock_days" {
  description = "Optional, Required if years is not specified) Number of days that you want to specify for the default retention period."
  type        = number
  default     = 30
}

variable "s3_bucket_lifecycle_rules" {
  description = "List of S3 bucket lifecycle rules"
  type        = map(object({
    id                            = string
    prefix                        = string
    expiration_days               = number
    transition_standard_ia_days   = number
    transition_glacier_days       = number
    filter_prefix                 = string
    filter_tags                   = map(string)
    status                        = string
  }))
  default = {
    log_rule = {
      id                            = "log"
      prefix                        = "log/"
      expiration_days               = 90
      transition_standard_ia_days   = 30
      transition_glacier_days       = 60
      filter_prefix                 = "log/"
      filter_tags                   = {
        rule      = "log"
        autoclean = "true"
      }
      status                        = "Enabled"
    }
  }
}