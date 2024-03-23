terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


provider "aws" {
  region                      = var.region
  profile                     = var.aws_credentials_profile
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  #skip_metadata_api_check     = true

  endpoints {
    s3       = "https://s3.amazonaws.com"
    iam      = "https://iam.amazonaws.com"
    kinesis  = "https://kinesis.amazonaws.com"
    glue     = "https://glue.amazonaws.com"
    firehose = "https://firehose.amazonaws.com"
    # s3      = "http://localhost:4566"
  }
}
