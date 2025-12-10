###################################################
# External ALB
###################################################

resource "aws_lb" "alb_external" {
  name               = "${var.project}-ext-alb"
  load_balancer_type = "application"

  internal = false

  subnets         = [for subnet in var.public_subnet_ids : subnet]
  security_groups = [aws_security_group.alb_sg.id]

  enable_deletion_protection = false

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-ext-alb"
    },
  )
}

###################################################
# Target Group
###################################################

resource "aws_lb_target_group" "web_tg" {
  name = "${var.project}-web-alb-tg"

  vpc_id = var.vpc_id

  target_type = "ip"
  port        = var.tg_port
  protocol    = var.tg_protocol

  health_check {
    enabled = true

    protocol = var.tg_health_check_protocol
    port     = var.tg_health_check_port
    path     = var.tg_health_check_path
    matcher  = var.tg_health_check_matcher

    healthy_threshold   = var.tg_healthy_threshould
    unhealthy_threshold = var.tg_unhealthy_threshould
    interval            = var.tg_health_check_interval
    timeout             = var.tg_health_check_timeout
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-web-alb-tg"
    },
  )
}

resource "aws_lb_target_group_attachment" "web_tg" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = var.tg_ec2_ip
  port             = var.tg_port
}

###################################################
# listner
###################################################

resource "aws_lb_listener" "web_alb_lstnr" {
  load_balancer_arn = aws_lb.alb_external.arn
  port              = var.listener_port
  protocol          = var.listener_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}
