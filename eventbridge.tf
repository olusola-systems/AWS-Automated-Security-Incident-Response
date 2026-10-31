resource "aws_cloudwatch_event_rule" "iam_security_events" {
  name        = "${var.project_name}-iam-events"
  description = "Detect IAM security-related API activity"

  event_pattern = jsonencode({
    source        = ["aws.iam"]
    "detail-type" = ["AWS API Call via CloudTrail"]

    detail = {
      eventSource = ["iam.amazonaws.com"]

      eventName = [
        "CreateUser",
        "DeleteUser",
        "CreateGroup",
        "DeleteGroup",
        "CreateAccessKey",
        "DeleteAccessKey",
        "AttachUserPolicy",
        "DetachUserPolicy",
        "PutUserPolicy",
        "DeleteUserPolicy",
        "AddUserToGroup",
        "RemoveUserFromGroup"
      ]
    }
  })

  tags = {
    Name        = "${var.project_name}-iam-events"
    Environment = var.environment
    Project     = "Week 35"
  }
}

resource "aws_cloudwatch_event_target" "incident_processor" {
  rule      = aws_cloudwatch_event_rule.iam_security_events.name
  target_id = "incident-processor"
  arn       = aws_lambda_function.incident_processor.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.incident_processor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.iam_security_events.arn
}
