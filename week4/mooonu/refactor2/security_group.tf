# bastion
resource "aws_security_group" "bastion" {
  name        = "practice-bastion-sg"
  description = "practice bastion security group"

  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # 모든 프로토콜 허용을 나타냄
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "practice-bastion-sg"
  }
}

# alb
resource "aws_security_group" "alb" {
  name        = "practice-alb-sg"
  description = "ALB security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 인터넷 전체에서 ALB 접근
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# web
resource "aws_security_group" "private" {
  name        = "practice-web-sg"
  description = "practice web security group"

  vpc_id = aws_vpc.main.id

  # SSH는 Bastion 보안 그룹에서 오는 것만 허용하도록
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # HTTP는 ALB 보안 그룹에서 오는 것만 허용하도록
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # 모든 프로토콜 허용을 나타냄
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "practice-web-sg"
  }
}