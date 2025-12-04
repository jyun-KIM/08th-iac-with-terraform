###################################################
# Bastion Host
###################################################

resource "aws_instance" "bastion" {
  ami           = var.ec2_ami
  instance_type = var.ec2_type

  subnet_id              = var.public_subnet_id[0]
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = var.key_name

  associate_public_ip_address = true
  disable_api_termination     = false # 실습 간 비활성화

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    encrypted   = true

    tags = merge(
      var.tags,
      {
        Name = "${var.project}-bastion-ebs"
      }
    )
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-bastion"
    },
  )

  lifecycle {
    prevent_destroy = false # 실습 비활성화
  }
}

###################################################
# Web Server
###################################################

resource "aws_instance" "web" {
  ami           = var.ec2_ami
  instance_type = var.ec2_type

  subnet_id              = var.private_subnet_id[0]
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.key_name

  disable_api_termination = false # 실습 간 비활성화

  user_data = file("${path.module}/scripts/web_nginx.sh")

  root_block_device {
    volume_size = var.web_root_volume_size
    volume_type = var.web_root_volume_type
    encrypted   = true
    tags = merge(
      var.tags,
      {
        Name = "${var.project}-web-ebs"
      }
    )
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-web"
    },
  )

  lifecycle {
    prevent_destroy = false # 실습 비활성화
  }
}