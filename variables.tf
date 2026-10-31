
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


