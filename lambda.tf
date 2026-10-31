
resource "aws_lambda_function" "incident_processor" {
  function_name = "${var.project_name}-processor"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "incident_processor.lambda_handler"
  runtime       = "python3.12"

  filename         = "${path.module}/lambda/incident_processor.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/incident_processor.zip")

  timeout     = 30
  memory_size = 128

  environment {
    variables = {
      TABLE_NAME    = aws_dynamodb_table.security_incidents.name
      SNS_TOPIC_ARN = aws_sns_topic.incident_alerts.arn
    }
  }

  tags = {
    Name        = "${var.project_name}-processor"
    Environment = var.environment
    Project     = "Week 35"
  }
}

