variable "aws_region" {
  description = "AWS region used for the project"
  type        = string
  default     = "us-east-1"
}

variable "budget_amount" {
  description = "Monthly AWS budget in USD"
  type        = number
  default     = 10
}

variable "budget_email" {
  description = "Email address that receives AWS budget alerts"
  type        = string
}
