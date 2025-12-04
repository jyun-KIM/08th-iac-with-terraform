variable "project" {}
variable "public_subnet_ids" {}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to resources"
  default     = {}
}

variable "vpc_id" {}

variable "tg_port" {
  default = 80
}

variable "tg_protocol" {
  default = "HTTP"
}

variable "tg_health_check_protocol" {
  default = "HTTP"
}

variable "tg_health_check_port" {
  default = 80
}

variable "tg_health_check_path" {
  default = "/"
}

variable "tg_health_check_matcher" {
  default = "200"
}

variable "tg_healthy_threshould" {
  default = 5
}

variable "tg_unhealthy_threshould" {
  default = 2
}

variable "tg_health_check_interval" {
  default = 30
}

variable "tg_health_check_timeout" {
  default = 5
}

variable "tg_ec2_ip" {}

variable "listener_port" {
  default = 80
}

variable "listener_protocol" {
  default = "HTTP"
}