
resource "aws_glue_catalog_database" "stream_events_database" {
  name       = "babble_stream-${var.environment}"
}


resource "aws_glue_crawler" "bronze_crawler" {
  database_name = aws_glue_catalog_database.stream_events_database.name
  role          = aws_iam_role.glue_crawler_role.arn
  name          = "bronze-crawler-${var.environment}"
  schedule      = "cron(0 0 * * ? *)"
  table_prefix  = "data-lake-"
  recrawl_policy {
    recrawl_behavior = "CRAWL_EVERYTHING"
  }
  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "DELETE_FROM_DATABASE"
  }

  configuration = jsonencode({
    Version = 1,
    CrawlerOutput =  {
      Partitions = {
        "AddOrUpdateBehavior" : "InheritFromTable"
        }
      }
  })

  s3_target {
    path = "s3://${aws_s3_bucket.babbel_data_lake.bucket}/bronze/"
    sample_size = 4
  }

  depends_on = [aws_glue_catalog_database.stream_events_database]
}


resource "aws_iam_role" "glue_crawler_role" {
  name = "glue-crawler-service-role"
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

resource "aws_iam_role_policy_attachment" "glue_crawler_s3_policy_attachment" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}
