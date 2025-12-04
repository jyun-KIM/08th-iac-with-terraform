variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to resources"
  default     = {}
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "all_cidr" {
  type        = string
  description = "Any IPv4 CIDR"
  default     = "0.0.0.0/0"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "enable_dns_hostname" {
  type        = bool
  description = "Enable DNS hostnames"
  default     = true
}

variable "enable_dns_support" {
  type        = bool
  description = "Enable DNS support"
  default     = true
}

variable "azs" {
  type        = list(string)
  description = "Availability zones"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "public subnet CIDR block"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "private subnet CIDR block"
}
