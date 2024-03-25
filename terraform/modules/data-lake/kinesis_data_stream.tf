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
