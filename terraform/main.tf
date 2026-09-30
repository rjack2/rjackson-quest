locals {
  constants = yamldecode(
    file("${path.module}/local-constants.yaml")
  )
}

module "budget" {
  source = "./modules/budget"

  name   = local.constants.budget.name
  amount = local.constants.budget.amount
  email  = var.BUDGET_EMAIL
}

module "ecr" {
  source = "./modules/ecr"

  repository_name = local.constants.ecr.repository_name
  project_name    = local.constants.project.name
}

module "networking" {
  source = "./modules/networking"

  project_name        = local.constants.project.name
  vpc_cidr            = local.constants.network.vpc_cidr
  public_subnet_cidrs = local.constants.network.public_subnet_cidrs
}

module "iam" {
  source = "./modules/iam"

  project_name = local.constants.project.name
}

module "acm" {
  source = "./modules/acm"

  domain_name = local.constants.domain.name
}

module "alb" {
  source = "./modules/alb"

  project_name      = local.constants.project.name
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  container_port    = local.constants.application.container_port
  health_check_path = local.constants.application.health_check_path
  https_enabled   = local.constants.domain.https_enabled
  certificate_arn = module.acm.certificate_arn
}

module "ecs" {
  source = "./modules/ecs"

  project_name   = local.constants.project.name
  container_name = local.constants.application.container_name
  container_port = local.constants.application.container_port
  cpu            = local.constants.application.cpu
  memory         = local.constants.application.memory
  desired_count  = local.constants.application.desired_count
  architecture   = local.constants.application.architecture
  image_uri      = "${module.ecr.repository_url}:${local.constants.application.image_tag}"

  public_subnet_ids     = module.networking.public_subnet_ids
  ecs_security_group_id = module.alb.ecs_security_group_id
  target_group_arn      = module.alb.target_group_arn
  execution_role_arn    = module.iam.ecs_execution_role_arn
}
