resource "aws_key_pair" "main" {
  key_name = "practice-key" # AWS 콘솔 키 페어 목록에 표시될 이름

  public_key = file(pathexpand("~/.ssh/practice-key.pub"))
}

# AMI 조회
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# web 서버 역할 인스턴스
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.main.key_name

  subnet_id              = aws_subnet.private[0].id # 2a
  vpc_security_group_ids = [aws_security_group.private.id]

  associate_public_ip_address = false

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Private Server</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "practice-web-2a"
  }
}

# bastion 역할 인스턴스
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.main.key_name

  subnet_id              = aws_subnet.public[0].id # 2a
  vpc_security_group_ids = [aws_security_group.bastion.id]

  associate_public_ip_address = true

  tags = {
    Name = "practice-bastion"
  }
}