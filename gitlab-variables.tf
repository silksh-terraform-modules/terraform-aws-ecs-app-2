# tworzenie pliku ze zmiennymi deploymentu do projektu w gitlabie
resource "local_file" "this-gitlab-environment" {
    content  = templatefile("${path.module}/templates/gitlab/project_variables.json", {
      env_scope                 = var.gitlab_branch
      access_key                = var.deployer_id
      secret_key                = var.deployer_secret
      docker_registry           = var.ecr_repository_url
      task_tag                  = var.docker_image_tag
      app_domain_name           = var.service_dns_name
      aws_region                = var.aws_region
      env_variable_s3_bucket    = var.environment_bucket_id
      ecs_cluster_name          = var.cluster_name
      ecs_service_name          = aws_ecs_service.this.name

    })
    filename = "./.terraform/${var.service_name}-${var.env_name}-gitlab-variables.json"
}

terraform {
  required_providers {
    gitlab = {
      source = "gitlabhq/gitlab"
      version = "~> 17.4"
    }
  }
}

locals {
  gitlab_variables = jsondecode(file("${path.module}/templates/gitlab/environment.json"))
  gitlab_variable_values = jsondecode(templatefile("${path.module}/templates/gitlab/environment-values.json", {
      access_key                = var.deployer_id
      secret_key                = var.deployer_secret
      docker_registry           = var.ecr_repository_url
      task_tag                  = var.docker_image_tag
      app_domain_name           = var.service_dns_name
      aws_region                = var.aws_region
      env_variable_s3_bucket    = var.environment_bucket_id
      ecs_cluster_name          = var.cluster_name
      ecs_service_name          = aws_ecs_service.this.name
  }))
}

resource "gitlab_project_variable" "this-gitlab-env-managed" {
  for_each = var.gitlab_project_id != 0 ? local.gitlab_variables.managed_by_tf : {}

  project   = var.gitlab_project_id
  environment_scope = var.gitlab_branch
  key = each.key
  value = local.gitlab_variable_values[each.key]
  variable_type = each.value.variable_type
}

resource "gitlab_project_variable" "this-gitlab-env-ignored" {
  for_each = var.gitlab_project_id != 0 ? local.gitlab_variables.ignored_changes : {}

  project   = var.gitlab_project_id
  environment_scope = var.gitlab_branch
  key = each.key
  value = local.gitlab_variable_values[each.key]
  variable_type = each.value.variable_type

  lifecycle {
    ignore_changes = [value]
  }
}
