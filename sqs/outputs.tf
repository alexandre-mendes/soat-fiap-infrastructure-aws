# Outputs for SQS FIFO queues
output "video_processing_queue_url" {
  description = "URL of the video processing FIFO queue"
  value       = aws_sqs_queue.video_processing_queue.url
}

output "video_processing_queue_arn" {
  description = "ARN of the video processing FIFO queue"
  value       = aws_sqs_queue.video_processing_queue.arn
}

output "video_processing_queue_name" {
  description = "Name of the video processing FIFO queue"
  value       = aws_sqs_queue.video_processing_queue.name
}

output "video_results_queue_url" {
  description = "URL of the video results FIFO queue"
  value       = aws_sqs_queue.video_results_queue.url
}

output "video_results_queue_arn" {
  description = "ARN of the video results FIFO queue"
  value       = aws_sqs_queue.video_results_queue.arn
}

output "video_results_queue_name" {
  description = "Name of the video results FIFO queue"
  value       = aws_sqs_queue.video_results_queue.name
}
