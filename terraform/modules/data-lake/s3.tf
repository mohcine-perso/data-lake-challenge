resource "aws_s3_bucket" "babbel_data_lake" {
  bucket = "babbel-data-lake-${var.environment}"
}

resource "aws_s3_bucket" "executables" {
  bucket = "executables-${var.environment}"
}

resource "aws_s3_object" "data_lake_etl_spark_job" {
  bucket = aws_s3_bucket.executables.id
  key    = "data_lake_etl.py"
  source = var.spark_jobs_file_path
}


resource "aws_s3_object" "lambda_trigger_job" {
  bucket = aws_s3_bucket.executables.id
  key    = "trigger_job.zip"
  source = var.lambda_file_path
}
