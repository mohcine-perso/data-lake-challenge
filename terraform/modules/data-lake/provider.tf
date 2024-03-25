terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


provider "aws" {
  region = var.region
  #profile                     = var.aws_credentials_profile
  s3_use_path_style           = true
  skip_credentials_validation = true
  access_key                  = "test"
  secret_key                  = "test"

  endpoints {
    s3          = "http://localhost:4566"
    iam         = "http://localhost:4566"
    kinesis     = "http://localhost:4566"
    glue        = "http://localhost:4566"
    firehose    = "http://localhost:4566"
    eventbridge = "http://localhost:4566"
    scheduler   = "http://localhost:4566"
    lambda      = "http://localhost:4566"
  }
}
