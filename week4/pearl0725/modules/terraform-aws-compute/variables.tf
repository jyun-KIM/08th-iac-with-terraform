variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to resources"
  default     = {}
}

variable "vpc_id" {}

variable "project" {
  type        = string
  description = "Project name"
}

variable "ec2_ami" {
  type        = string
  description = "AMI ID"
  default     = "ami-04fcc2023d6e37430"
}

variable "ec2_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type        = string
  description = "Key pair name"
  default     = "practice-key" 
}

variable "root_volume_size" {
  type = number
}

variable "root_volume_type" {
  type = string
}

variable "web_root_volume_size" {
  type = number
}

variable "web_root_volume_type" {
  type = string
}

variable "private_subnet_id" {}

variable "public_subnet_id" {}
