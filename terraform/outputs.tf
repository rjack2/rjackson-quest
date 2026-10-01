output "budget_name" {
  description = "Name of the AWS Budget"
  value       = module.budget.budget_name
}

output "ecr_repository_url" {
  description = "URL used to push container images to ECR"
  value       = module.ecr.repository_url
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs.service_name
}

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "application_url" {
  description = "HTTP URL for the deployed application"
  value       = local.constants.domain.https_enabled ? "https://${local.constants.domain.name}" : "http://${module.alb.alb_dns_name}"
}

output "acm_validation_records" {
  value = module.acm.domain_validation_options
}

output "acm_certificate_arn" {
  value = module.acm.certificate_arn
}