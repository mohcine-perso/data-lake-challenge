resource "aws_kinesis_stream" "events_data_stream" {
  name             = "babbel-events-${var.environment}"
  shard_count      = 1
  retention_period = 48

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role" "kinesis_role" {
  name               = "kinesis-data-stream-role"
  assume_role_policy = data.aws_iam_policy_document.kinesis_assumed_role_policy.json
}

resource "aws_iam_policy" "write_to_firehose_policy" {
  name   = "write-to-firehose-policy"
  policy = data.aws_iam_policy_document.write_to_firehose_policy.json
}


resource "aws_iam_role_policy_attachment" "kinesis_role_policy_attachment" {
  role       = aws_iam_role.events_delivery_stream_role.name
  policy_arn = aws_iam_policy.write_to_firehose_policy.arn
}


data "aws_iam_policy_document" "write_to_firehose_policy" {
  statement {
    sid    = "write_to_firehose"
    effect = "Allow"
    actions = [
      "firehose:*",
      #"firehose:PutRecord"
    ]
    resources = [
      aws_kinesis_firehose_delivery_stream.events_delivery_stream.arn,
    ]
  }
}


data "aws_iam_policy_document" "kinesis_assumed_role_policy" {
  statement {
    sid     = "assumed_role"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["kinesis.amazonaws.com"]
    }
  }
}
