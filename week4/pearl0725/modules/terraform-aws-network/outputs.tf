output "public_subnet_ids" {
  description = "public subnet ids"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "private subnet ids"
  value       = aws_subnet.private[*].id
}

output "vpc_id" {
  description = "vpc id"
  value       = aws_vpc.this.id
}