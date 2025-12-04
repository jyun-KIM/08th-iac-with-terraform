###################################################
# VPC
###################################################

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  enable_dns_hostnames = true # default
  enable_dns_support   = true # default

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-vpc"
    },
  )
}
