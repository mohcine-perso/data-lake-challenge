variable "region" {
  type    = string
  default = ""
}

variable "environment" {
  type    = string
  default = ""
}

variable "aws_credentials_profile" {
  type    = string
  default = ""
}

variable "spark_jobs_file_path" {
  type    = string
  default = ""
}

variable "lambda_file_path" {
  type    = string
  default = ""
}
