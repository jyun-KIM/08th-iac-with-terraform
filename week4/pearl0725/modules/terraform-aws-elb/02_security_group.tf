resource "aws_security_group" "alb_sg" {
  name        = "${var.project}-ext-alb-sg"
  description = "alb security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "web"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = []
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = []
  }
}