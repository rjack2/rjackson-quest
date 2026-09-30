variable "name" { type = string }
variable "amount" { type = number }
variable "email" {
  type      = string
  sensitive = true
}
