variable "project_name" { type = string }
variable "container_name" { type = string }
variable "container_port" { type = number }
variable "cpu" { type = number }
variable "memory" { type = number }
variable "desired_count" { type = number }
variable "architecture" { type = string }
variable "image_uri" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "ecs_security_group_id" { type = string }
variable "target_group_arn" { type = string }
variable "execution_role_arn" { type = string }
variable "secret_word" {
  description = "SECRET_WORD environment variable injected into the container"
  type        = string
  sensitive   = true
}
