resource "aws_kinesis_firehose_delivery_stream" "events_delivery_stream" {
  name        = "babbel-events-delivery-stream-${var.environment}"
  destination = "extended_s3"

  extended_s3_configuration {
    bucket_arn          = aws_s3_bucket.babbel_data_lake.arn
    role_arn            = aws_iam_role.events_delivery_stream_role.arn
    prefix              = "bronze/"
    error_output_prefix = "firehose-errors/"
    buffering_size      = 1
    buffering_interval  = 60
    compression_format  = "UNCOMPRESSED"
    processing_configuration {
      enabled = true
      processors {
        type = "AppendDelimiterToRecord"
      }
    }


    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "/aws/kinesisfirehose/babbel-events-delivery-stream-${var.environment}"
      log_stream_name = "S3Delivery"
    }
  }

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.events_data_stream.arn
    role_arn           = aws_iam_role.events_delivery_stream_role.arn
  }


}


resource "aws_iam_role" "events_delivery_stream_role" {
  name = "firehose-delivery-stream-service-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "firehose.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "read_stream_role_policy_attachment" {
  role       = aws_iam_role.events_delivery_stream_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "read_glue_policy_attachment" {
  role       = aws_iam_role.events_delivery_stream_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "write_stream_s3_role_policy_attachment" {
  role       = aws_iam_role.events_delivery_stream_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
