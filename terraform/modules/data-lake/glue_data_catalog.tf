
resource "aws_glue_catalog_database" "stream_events_database" {
  catalog_id = "babble_data_catalog"
  name       = "babble_stream"
}

resource "aws_glue_catalog_table" "bronze_events_table" {
  name          = "bronze_events"
  catalog_id    = aws_glue_catalog_database.stream_events_database.catalog_id
  database_name = aws_glue_catalog_database.stream_events_database.name
  table_type    = "EXTERNAL_TABLE"
  owner         = "owner"
  retention     = 0

  storage_descriptor {

    stored_as_sub_directories = true
    location                  = "${aws_s3_bucket.babbel_data_lake.bucket}/bronze"

    columns {
      name = "event_uuid"
      type = "bigint"
    }
    columns {
      name = "event_name"
      type = "string"
    }
    columns {
      name = "created_at"
      type = "bigint"
    }

    input_format      = "org.apache.hadoop.mapred.TextInputFormat"
    output_format     = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    compressed        = false
    number_of_buckets = 0
  }
}


resource "aws_glue_crawler" "bronze_crawler" {
  database_name = aws_glue_catalog_database.stream_events_database.name
  role          = aws_iam_role.glue_crawler_role.arn
  name          = "bronze_crawler"
  schedule      = "cron(*/5 * * * *)"
  #schedule      = "cron(0 * * * ? *)"

  configuration = jsonencode({
    Version = 1,
    CrawlerOutput =  {
      Partitions = {
        "AddOrUpdateBehavior" : "InheritFromTable"
        }
      },
      Grouping = {
        TableGroupingPolicy = "CombineCompatibleSchemas"
      }
  })

  s3_target {
    path = "s3://${aws_s3_bucket.babbel_data_lake.bucket}/bronze"
  }
}


resource "aws_iam_role" "glue_crawler_role" {
  name = "glue-crawler-role"
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
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
