
variable "aws_region" {
  description = "AWS region for the incident response infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "week35-incident-response"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "notification_email" {
  description = "Email address receiving security incident notifications"
  type        = string
}

variable "remediation_test_username" {
  description = "Dedicated IAM test user for controlled remediation"
  type        = string
  default     = "week35-remediation-test-user"
}

variable "remediation_dry_run" {
  description = "When true, remediation is simulated without changing IAM"
  type        = bool
  default     = true
}

