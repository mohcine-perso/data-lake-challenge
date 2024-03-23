resource "aws_s3_bucket" "babbel_data_lake" {
  bucket = "babbel-data-lake-${var.environment}"
}

resource "aws_s3_bucket" "sparks_jobs" {
  bucket = "sparks-jobs-${var.environment}"
}
