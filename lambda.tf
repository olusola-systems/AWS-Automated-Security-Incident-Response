
# Original Lambda retained temporarily during migration
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

# 1. Incident Detector
resource "aws_lambda_function" "incident_detector" {
  function_name = "${var.project_name}-detector"
  role          = aws_iam_role.incident_detector.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.12"

  filename         = "${path.module}/lambda/incident_detector.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/incident_detector.zip")

  timeout     = 30
  memory_size = 128

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.security_incidents.name
    }
  }

  tags = {
    Name        = "${var.project_name}-detector"
    Environment = var.environment
    Project     = "Week 35"
  }
}

# 2. Incident Classifier
resource "aws_lambda_function" "incident_classifier" {
  function_name = "${var.project_name}-classifier"
  role          = aws_iam_role.incident_classifier.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.12"

  filename         = "${path.module}/lambda/incident_classifier.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/incident_classifier.zip")

  timeout     = 30
  memory_size = 128

  environment {
    variables = {
      TABLE_NAME                = aws_dynamodb_table.security_incidents.name
      REMEDIATION_TEST_USERNAME = var.remediation_test_username
    }
  }

  tags = {
    Name        = "${var.project_name}-classifier"
    Environment = var.environment
    Project     = "Week 35"
  }
}

# 3. Notification Handler
resource "aws_lambda_function" "notification_handler" {
  function_name = "${var.project_name}-notification"
  role          = aws_iam_role.notification_handler.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.12"

  filename         = "${path.module}/lambda/notification_handler.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/notification_handler.zip")

  timeout     = 30
  memory_size = 128

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.incident_alerts.arn
    }
  }

  tags = {
    Name        = "${var.project_name}-notification"
    Environment = var.environment
    Project     = "Week 35"
  }
}

# 4. Remediation Handler
resource "aws_lambda_function" "remediation_handler" {
  function_name = "${var.project_name}-remediation"
  role          = aws_iam_role.remediation_handler.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.12"

  filename         = "${path.module}/lambda/remediation_handler.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/remediation_handler.zip")

  timeout     = 30
  memory_size = 128

  environment {
    variables = {
      TEST_IAM_USERNAME = var.remediation_test_username
      DRY_RUN           = tostring(var.remediation_dry_run)
    }
  }

  tags = {
    Name        = "${var.project_name}-remediation"
    Environment = var.environment
    Project     = "Week 35"
  }
}

