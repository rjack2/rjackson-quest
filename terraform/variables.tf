variable "aws_region" {
  description = "AWS region used for the project"
  type        = string
  default     = "us-east-1"
}

variable "BUDGET_EMAIL" {
  description = "Email address for AWS budget notifications"
  type        = string
  sensitive   = true
}

variable "SECRET_WORD" {
  description = "Secret word obtained from the application index page"
  type        = string
  sensitive   = true
}