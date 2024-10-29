resource "aws_lb_target_group" "secondary" {
    count = length(var.lb_listener_arn_secondary) > 0 ? 1 : 0      
    deregistration_delay          = var.deregistration_delay
    load_balancing_algorithm_type = var.load_balancing_algorithm_type_secondary
    name                          = "${var.service_name}-${var.env_name}-internal-${substr(uuid(), 0, 3)}"
    port                          = length(var.container_port_secondary) > 0 ? var.container_port_secondary : var.container_port 
    protocol                      = "HTTP"
    slow_start                    = 0
    target_type                   = "instance"
    vpc_id                        = var.vpc_id

    health_check {
        enabled             = true
        healthy_threshold   = var.target_group_healthy_threshold
        unhealthy_threshold = var.target_group_unhealthy_threshold
        interval            = var.target_group_health_interval
        matcher             = var.target_group_health_matcher
        path                = var.target_group_health_path
        port                = var.target_group_health_port_secondary
        protocol            = "HTTP"
        timeout             = var.target_group_health_timeout
    }

    stickiness {
        cookie_duration = var.stickiness_cookie_duration
        enabled         = var.stickiness_enabled
        type            = var.stickiness_type
    }

    lifecycle {
      create_before_destroy = true
      ignore_changes        = [name]
    }
}

resource "aws_lb_listener_rule" "secondary" {
  
  count = length(var.lb_listener_arn_secondary) > 0 ? 1 : 0

  listener_arn = var.lb_listener_arn_secondary
  
  condition {
    host_header {
      values = [
        aws_route53_record.secondary[0].name
      ]
    }
  }

  dynamic "condition" {
    for_each = var.security_header_secondary != null ? [var.security_header_secondary] : []

    content {
      http_header {
        http_header_name   = condition.value.header_name
        values = condition.value.values
      }
    }
  }

  action {
    target_group_arn = aws_lb_target_group.secondary[0].arn
    type             = "forward"
  }
}
