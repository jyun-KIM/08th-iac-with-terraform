output "bastion_public_ip" {
  description = "SSH 접속용 Bastion Public IP"
  value       = aws_instance.bastion.public_ip
}

output "web_private_ip" {
  description = "내부 접속용 Web Server Private IP"
  value       = aws_instance.web.private_ip
}