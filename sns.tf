
resource "aws_sns_topic" "incident_alerts" {
  name = "${var.project_name}-alerts"

  tags = {
    Name        = "${var.project_name}-alerts"
    Environment = var.environment
    Project     = "Week 35"
  }
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.incident_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

