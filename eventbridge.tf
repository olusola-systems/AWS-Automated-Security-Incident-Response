
# Detect IAM security-related API activity through CloudTrail
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

# Start the Step Functions incident response workflow
resource "aws_cloudwatch_event_target" "incident_processor" {
  rule      = aws_cloudwatch_event_rule.iam_security_events.name
  target_id = "incident-response-workflow"
  arn       = aws_sfn_state_machine.incident_response.arn

  role_arn = aws_iam_role.eventbridge_start_workflow.arn
}
