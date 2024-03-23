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
