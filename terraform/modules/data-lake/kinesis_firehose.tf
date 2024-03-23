resource "aws_kinesis_firehose_delivery_stream" "events_delivery_stream" {
  name        = "babbel-events-delivery-stream"
  destination = "extended_s3"

  extended_s3_configuration {
    bucket_arn          = aws_s3_bucket.babbel_data_lake.arn
    role_arn            = aws_iam_role.events_delivery_stream_role.arn
    prefix              = "bronze/"
    error_output_prefix = "firehose-errors/"
    buffering_size      = 1
    buffering_interval  = 60


    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "firehose-${aws_glue_catalog_table.bronze_events_table.name}"
      log_stream_name = "S3Delivery"
    }
  }

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.events_data_stream.arn
    role_arn           = aws_iam_role.events_delivery_stream_role.arn
  }


}


resource "aws_iam_role" "events_delivery_stream_role" {
  name               = "firehose-delivery-stream-role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assumed_role_policy.json
}

resource "aws_iam_policy" "read_data_stream_policy" {
  name   = "read-data-stream-policy"
  policy = data.aws_iam_policy_document.read_kinesis_data_stream_policy.json
}

resource "aws_iam_policy" "write_delivery_stream_policy" {
  name   = "write-to-s3-stream-policy"
  policy = data.aws_iam_policy_document.write_to_s3_policy.json
}

resource "aws_iam_role_policy_attachment" "read_stream_role_policy_attachment" {
  role       = aws_iam_role.events_delivery_stream_role.name
  policy_arn = aws_iam_policy.read_data_stream_policy.arn
}

resource "aws_iam_role_policy_attachment" "read_glue_policy_attachment" {
  role       = aws_iam_role.events_delivery_stream_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "write_stream_s3_role_policy_attachment" {
  role       = aws_iam_role.events_delivery_stream_role.name
  policy_arn = aws_iam_policy.write_delivery_stream_policy.arn
}

data "aws_iam_policy_document" "read_kinesis_data_stream_policy" {
  statement {
    sid    = "read_kinesis_data_stream"
    effect = "Allow"
    actions = [
      "kinesis:Get*",
      "kinesis:DescribeStream",
      "kinesis:ListStreams"
    ]
    resources = [
      aws_kinesis_stream.events_data_stream.arn,
    ]
  }
}

data "aws_iam_policy_document" "write_to_s3_policy" {
  statement {
    sid    = "write_to_s3"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetBucketLocation"
    ]
    resources = [
      aws_s3_bucket.babbel_data_lake.arn,
      "${aws_s3_bucket.babbel_data_lake.arn}/*"
    ]

  }
}

data "aws_iam_policy_document" "firehose_assumed_role_policy" {
  statement {
    sid     = "assumed_role"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}
