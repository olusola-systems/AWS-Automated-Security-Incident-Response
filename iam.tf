
# Common Lambda trust policy
data "aws_iam_policy_document" "lambda_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Step Functions trust policy
data "aws_iam_policy_document" "step_functions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

# EventBridge trust policy
data "aws_iam_policy_document" "eventbridge_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

# Temporary existing role.
# Retain until the original Lambda is removed.
resource "aws_iam_role" "lambda_execution_role" {
  name               = "${var.project_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

resource "aws_iam_role_policy" "lambda_permissions" {
  name = "${var.project_name}-lambda-permissions"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem"]
        Resource = aws_dynamodb_table.security_incidents.arn
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.incident_alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Incident Detector role
resource "aws_iam_role" "incident_detector" {
  name               = "${var.project_name}-detector-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

resource "aws_iam_role_policy" "incident_detector" {
  name = "${var.project_name}-detector-policy"
  role = aws_iam_role.incident_detector.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:PutItem"]
      Resource = aws_dynamodb_table.security_incidents.arn
    }]
  })
}

# Incident Classifier role
resource "aws_iam_role" "incident_classifier" {
  name               = "${var.project_name}-classifier-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

# Notification Handler role
resource "aws_iam_role" "notification_handler" {
  name               = "${var.project_name}-notification-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

resource "aws_iam_role_policy" "notification_handler" {
  name = "${var.project_name}-notification-policy"
  role = aws_iam_role.notification_handler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sns:Publish"]
      Resource = aws_sns_topic.incident_alerts.arn
    }]
  })
}

# Remediation Handler role
resource "aws_iam_role" "remediation_handler" {
  name               = "${var.project_name}-remediation-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

resource "aws_iam_role_policy" "remediation_handler" {
  name = "${var.project_name}-remediation-policy"
  role = aws_iam_role.remediation_handler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "iam:UpdateAccessKey"
      ]
      Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.remediation_test_username}"
    }]
  })
}

# CloudWatch Logs permissions for the four new Lambda roles
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  for_each = {
    detector     = aws_iam_role.incident_detector.name
    classifier   = aws_iam_role.incident_classifier.name
    notification = aws_iam_role.notification_handler.name
    remediation  = aws_iam_role.remediation_handler.name
  }

  role       = each.value
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Step Functions execution role
resource "aws_iam_role" "step_functions" {
  name               = "${var.project_name}-step-functions-role"
  assume_role_policy = data.aws_iam_policy_document.step_functions_trust.json
}

resource "aws_iam_role_policy" "step_functions_invoke_lambda" {
  name = "${var.project_name}-step-functions-invoke-lambda"
  role = aws_iam_role.step_functions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["lambda:InvokeFunction"]
      Resource = [
        aws_lambda_function.incident_detector.arn,
        aws_lambda_function.incident_classifier.arn,
        aws_lambda_function.notification_handler.arn,
        aws_lambda_function.remediation_handler.arn
      ]
    }]
  })
}

# Step Functions permission to update incident records
resource "aws_iam_role_policy" "step_functions_dynamodb" {
  name = "${var.project_name}-step-functions-dynamodb"
  role = aws_iam_role.step_functions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:UpdateItem"
      ]
      Resource = aws_dynamodb_table.security_incidents.arn
    }]
  })
}

# EventBridge permission to start the Step Functions workflow
resource "aws_iam_role" "eventbridge_start_workflow" {
  name               = "${var.project_name}-eventbridge-role"
  assume_role_policy = data.aws_iam_policy_document.eventbridge_trust.json
}

resource "aws_iam_role_policy" "eventbridge_start_workflow" {
  name = "${var.project_name}-eventbridge-start-workflow"
  role = aws_iam_role.eventbridge_start_workflow.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["states:StartExecution"]
      Resource = aws_sfn_state_machine.incident_response.arn
    }]
  })
}

