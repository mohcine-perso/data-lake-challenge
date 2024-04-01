resource "aws_lambda_function" "glue_job_invoker" {
  function_name = "glue-job-lambda-trigger-${var.environment}"
  runtime       = "python3.12"
  handler       = "trigger_job.handler"
  s3_bucket     = aws_s3_object.lambda_trigger_job.bucket
  s3_key        = aws_s3_object.lambda_trigger_job.key
  role          = aws_iam_role.glue_trigger_lambda_service_role.arn

}

resource "aws_iam_role" "glue_trigger_lambda_service_role" {
  name = "glue-job-lambda-trigger-service-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = [
          "lambda.amazonaws.com",
          "scheduler.amazonaws.com"
        ]
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "glue_trigger_lambda_glue_service_role_policy_attachment" {
  role       = aws_iam_role.glue_trigger_lambda_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}


resource "aws_iam_role_policy_attachment" "glue_trigger_lambda_scheduler_service_role_policy_attachment" {
  role       = aws_iam_role.glue_trigger_lambda_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEventBridgeSchedulerFullAccess"
}


resource "aws_scheduler_schedule" "to_silver_scheduler" {
  name       = "to-silver-${var.environment}"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 0 * * ? *)"

  target {
    arn      = aws_lambda_function.glue_job_invoker.arn
    role_arn = aws_iam_role.glue_trigger_lambda_service_role.arn
    input = jsonencode({
      "etl_direction" : "to-silver",
      "bucket_name" : "${aws_s3_bucket.babbel_data_lake.bucket}",
      "job_name" : "${aws_glue_job.data_lake_etl_job.name}"
    })
  }


}


resource "aws_scheduler_schedule" "to_gold_scheduler" {
  name       = "to-gold-${var.environment}"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 1 * * ? *)"

  target {
    arn      = aws_lambda_function.glue_job_invoker.arn
    role_arn = aws_iam_role.glue_trigger_lambda_service_role.arn
    input = jsonencode({
      "etl_direction" : "to-gold",
      "bucket_name" : "${aws_s3_bucket.babbel_data_lake.bucket}",
      "job_name" : "${aws_glue_job.data_lake_etl_job.name}"
    })
  }
}
