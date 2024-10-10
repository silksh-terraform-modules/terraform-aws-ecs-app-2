output "app_fqdn" {
  value = try(aws_route53_record.this[0].fqdn, "")
}

output "app_fqdn_secondary" {
  value = try(aws_route53_record.secondary[*].fqdn, "")
}

output "aws_lb_target_group_arn" {
  value = try(aws_lb_target_group.this[0].arn, "")
}

output "app_service_name" {
  value = aws_ecs_service.this.name
}

output "app_repository_url" {
  value = var.ecr_repository_url
}

output "app_env_bucket_id" {
  value = var.environment_bucket_id
}
