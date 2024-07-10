resource "aws_lb_target_group" "this" {
    count = length(var.service_dns_name) > 0 ? 1 : 0
    deregistration_delay          = var.deregistration_delay
    load_balancing_algorithm_type = var.load_balancing_algorithm_type
    name                          = "${var.service_name}-${var.env_name}-${substr(uuid(), 0, 3)}"
    port                          = var.container_port
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
        port                = var.target_group_health_port
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

resource "aws_lb_listener_rule" "this" {
  count = length(var.service_dns_name) > 0 ? 1 : 0
  listener_arn = var.lb_listener_arn
  # priority     = var.listener_priority

  condition {
    host_header {
      values = (
        length(var.other_service_dns_names) > 0 ? 
          concat(
            [aws_route53_record.this[0].name],
            var.other_service_dns_names
          ) :
        [aws_route53_record.this[0].name]
      )
    }
  }

  action {
    target_group_arn = aws_lb_target_group.this[0].arn
    type             = "forward"
  }
}