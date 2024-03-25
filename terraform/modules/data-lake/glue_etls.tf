resource "aws_glue_job" "data_lake_etl_job" {
  name     = "datalake-etl-job-${var.environment}"
  role_arn = aws_iam_role.glue_job_role.arn
  worker_type = "G.1X"
  number_of_workers = 2
  execution_class = "STANDARD"

  command {
    script_location = "s3://${aws_s3_bucket.executables.bucket}/data_lake_elt.py"
    python_version = "3"
  }

  depends_on = [ aws_s3_object.data_lake_etl_spark_job ]
}

resource "aws_iam_role" "glue_job_role" {
  name = "glue-job-service-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "glue.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "glue_job_policy_attachment" {
  role       = aws_iam_role.glue_job_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}
