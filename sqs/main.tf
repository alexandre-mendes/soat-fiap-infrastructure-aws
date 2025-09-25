# SQS Queues for Video Processing

# Video Processing Queue (FIFO)
resource "aws_sqs_queue" "video_processing_queue" {
  name                        = "video-processing-queue.fifo"
  fifo_queue                 = true
  content_based_deduplication = true

  # Message retention period (14 days)
  message_retention_seconds = 1209600

  # Visibility timeout (5 minutes)
  visibility_timeout_seconds = 300

  # Maximum message size (256 KB)
  max_message_size = 262144

  # Delivery delay (0 seconds)
  delay_seconds = 0

  tags = {
    Name        = "video-processing-queue"
    Environment = var.environment
    Purpose     = "Video processing tasks FIFO"
  }
}

# Video Results Queue (FIFO)
resource "aws_sqs_queue" "video_results_queue" {
  name                        = "video-results-queue.fifo"
  fifo_queue                 = true
  content_based_deduplication = true

  # Message retention period (14 days)
  message_retention_seconds = 1209600

  # Visibility timeout (1 hour)
  visibility_timeout_seconds = 3600

  # Maximum message size (256 KB)
  max_message_size = 262144

  # Delivery delay (0 seconds)
  delay_seconds = 0

  tags = {
    Name        = "video-results-queue"
    Environment = var.environment
    Purpose     = "Video processing results FIFO"
  }
}


