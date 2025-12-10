resource "aws_security_group" "bastion_sg" {
  name        = "${var.project}-bastion-sg"
  description = "bastion security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = []
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-bastion-sg"
    },
  )
}
resource "aws_security_group" "web_sg" {
  name        = "${var.project}-web-sg"
  description = "web server security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "Bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [format("%s/32", aws_instance.bastion.private_ip)]
  }

  ingress {
    description = "ALB"
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