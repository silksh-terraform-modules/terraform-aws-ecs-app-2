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
    scheduling_strategy                = "REPLICA"
    task_definition                    = aws_ecs_task_definition.this.arn
    enable_execute_command             = var.enable_execute_command

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

    ordered_placement_strategy {
        field = "attribute:ecs.availability-zone"
        type  = "spread"
    }

    ordered_placement_strategy {
        field = "instanceId"
        type  = "spread"
    }

    dynamic placement_constraints {
      for_each = length(var.purchase_option) > 0 ? [1] : []
      content {
        type  = "memberOf"
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
  count = length(var.zone_id) > 0 ? 1 : 0
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
  count = length(var.zone_id_secondary) > 0 ? 1 : 0
  zone_id = var.zone_id_secondary
  name    = var.service_dns_name_secondary
  type    = "A"

  alias {
    name                   = var.lb_dns_name_secondary
    zone_id                = var.lb_zone_id_secondary
    evaluate_target_health = true
  }
}