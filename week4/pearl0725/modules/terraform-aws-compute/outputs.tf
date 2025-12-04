output "web_instance_id" {
  description = "value"
  value = aws_instance.web.id
}

output "web_instance_ip" {
  description = "value"
  value = aws_instance.web.private_ip
}