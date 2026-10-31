
resource "aws_dynamodb_table" "security_incidents" {
  name         = "${var.project_name}-incidents"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "incident_id"

  attribute {
    name = "incident_id"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-incidents"
    Environment = var.environment
    Project     = "Week 35"
  }
}

