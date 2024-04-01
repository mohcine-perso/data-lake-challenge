variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "environment" {
  type    = string
  default = "staging"
}

variable "aws_credentials_profile" {
  type    = string
  default = "localstack"
}

variable "spark_jobs_file_path" {
  type    = string
  default = ""
}

variable "lambda_file_path" {
  type    = string
  default = ""
}
