output "lambda_function_name" {
  description = "Name of the incident processor Lambda function"
  value       = aws_lambda_function.incident_processor.function_name
}

output "dynamodb_table_name" {
  description = "Name of the security incidents DynamoDB table"
  value       = aws_dynamodb_table.security_incidents.name
}

output "sns_topic_arn" {
  description = "ARN of the incident alert SNS topic"
  value       = aws_sns_topic.incident_alerts.arn
}

output "eventbridge_rule_name" {
  description = "Name of the IAM security monitoring EventBridge rule"
  value       = aws_cloudwatch_event_rule.iam_security_events.name
}
