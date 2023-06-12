resource "aws_s3_bucket" "b" {
  bucket        = "example-flow-logtesting"
  force_destroy = true
}

data "aws_iam_policy_document" "default" {
  statement {
    sid    = "AWSCloudTrailCreateLogStream2014110"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl",
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.b.bucket}",
    ]
  }

  statement {
    sid    = "AWSCloudTrailPutLogEvents20141101"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.b.bucket}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control",
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "CloudTrailS3Bucket" {
  bucket     = aws_s3_bucket.b.id
  depends_on = [aws_s3_bucket.b]
  policy     = data.aws_iam_policy_document.default.json
}

resource "aws_kms_key" "a" {
  description             = "KMS key 1"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags = {
    Name = "test"
  }
}

resource "aws_cloudtrail" "default" {
  name                          = "chaos"
  enable_logging                = true
  s3_bucket_name                = aws_s3_bucket.b.bucket
  enable_log_file_validation    = true
  is_multi_region_trail         = false
  include_global_service_events = true
#   kms_key_id                    = aws_kms_key.a.arn
  s3_key_prefix                 = "cloudtrail"
  depends_on = [
    aws_s3_bucket_policy.CloudTrailS3Bucket
  ]
}
data "aws_caller_identity" "current" {

}

resource "aws_inspector2_enabler" "test" {
  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = ["EC2"]
}



resource "aws_flow_log" "example" {
  log_destination      = aws_s3_bucket.b.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = "vpc-01258b4284ea0ccd6"
  destination_options {
    per_hour_partition = true
  }
}

resource "aws_guardduty_detector" "MyDetector" {
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  datasources {
    s3_logs {
      enable = true
    }

    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }
}

resource "aws_wafv2_web_acl" "example" {
  name     = "watermelon"
  scope    = "CLOUDFRONT"
  provider = aws.east
  default_action {
    allow {}
  }

  rule {
    name     = "rule-1"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 10000
        aggregate_key_type = "IP"

        scope_down_statement {
          geo_match_statement {
            country_codes = ["US", "NL"]
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "watermelon"
      sampled_requests_enabled   = false
    }
  }

  tags = {
    Name = "watermelon"
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "waf-watermelon"
    sampled_requests_enabled   = false
  }
}

resource "aws_securityhub_account" "example" {
}
