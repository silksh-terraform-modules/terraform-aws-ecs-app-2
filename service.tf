resource "aws_ecs_service" "this" {
  cluster                            = var.cluster_id
  deployment_maximum_percent         = var.deploy_max_percent
  deployment_minimum_healthy_percent = var.deploy_min_percent
  desired_count                      = var.desired_count
  enable_ecs_managed_tags            = false
  health_check_grace_period_seconds  = var.healt_check_grace_period
  launch_type                        = var.launch_type
  name                               = var.service_name
  #propagate_tags                     = "NONE"
  scheduling_strategy = "REPLICA"
  # task_definition                    = var.limit_cpu_mem ? aws_ecs_task_definition.this[0].arn : aws_ecs_task_definition.this_no_limits[0].arn
  task_definition        = aws_ecs_task_definition.this.arn
  enable_execute_command = var.enable_execute_command

  deployment_controller {
    type = "ECS"
  }

  dynamic "load_balancer" {
    for_each = length(var.service_dns_name) > 0 ? [1] : []
    content {
      container_name   = var.service_name
      container_port   = var.container_port
      target_group_arn = aws_lb_target_group.this[0].arn
    }
  }

  dynamic "load_balancer" {
    for_each = length(var.lb_dns_name_secondary) > 0 ? [1] : []
    content {
      container_name   = var.service_name
      container_port   = length(var.container_port_secondary) > 0 ? var.container_port_secondary : var.container_port
      target_group_arn = aws_lb_target_group.secondary[0].arn
    }
  }

  dynamic "network_configuration" {
      for_each = var.service_discovery_namespace != null ? [1] : []
      content {
          subnets          = var.subnet_ids
          security_groups  = var.security_group_ids
          assign_public_ip = var.assign_public_ip
      }
  }

  dynamic "service_registries" {
      for_each = var.service_discovery_namespace != null ? [1] : []
      content {
          registry_arn = aws_service_discovery_service.this[0].arn
      }
  }
  

  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }

  ordered_placement_strategy {
    field = "instanceId"
    type  = "spread"
  }

  dynamic "placement_constraints" {
    for_each = length(var.purchase_option) > 0 ? [1] : []
    content {
      type       = "memberOf"
      expression = "attribute:purchase-option == ${var.purchase_option}"
    }
  }

  depends_on = [
    aws_lb_target_group.this[0]
  ]

  lifecycle {
    ignore_changes = [
      desired_count
    ]
  }
}

resource "aws_route53_record" "this" {
  count   = length(var.zone_id) > 0 ? 1 : 0
  zone_id = var.zone_id
  name    = var.service_dns_name
  type    = "A"

  alias {
    name                   = var.lb_dns_name
    zone_id                = var.lb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "secondary" {
  count   = length(var.zone_id_secondary) > 0 ? 1 : 0
  zone_id = var.zone_id_secondary
  name    = var.service_dns_name_secondary
  type    = "A"

  alias {
    name                   = var.lb_dns_name_secondary
    zone_id                = var.lb_zone_id_secondary
    evaluate_target_health = true
  }
}

resource "aws_service_discovery_service" "this" {
    count = var.service_discovery_namespace != null ? 1 : 0
    
    name = var.service_name
    dns_config {
        namespace_id = var.service_discovery_namespace
        
        dns_records {
            ttl  = 10
            type = "A"
        }
    }

    health_check_custom_config {
        failure_threshold = 1
    }
}
