// =====
// IGW (enable_igw == true인 경우에만)
resource "aws_internet_gateway" "this" {
  count  = local.enable_igw ? 1 : 0
  vpc_id = local.vpc_id

  tags = merge(
    local.module_tag,
    {
      Name = "${local.vpc_name}-igw",
    }
  )
}

resource "aws_route" "public_igw" {
  count = local.enable_igw ? 1 : 0

  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public[count.index].id
  gateway_id             = aws_internet_gateway.this[count.index].id
}

// =====
// NAT 

locals {
  nat = var.attribute.nat // nat.create == true인 경우에만

  // nat.per_az == true -> nat.subnet 서브넷 az별 NAT GW 생성
  // nat.per_az == false -> 1개만 생성
  nat_azs = slice(local.subnet_azs, 0, local.nat.per_az ? try(length(local.subnets[local.nat.subnet]), 0) : 1)
  nat_set = local.nat.create ? toset(local.nat_azs) : toset([])
}

// EIP 생성
resource "aws_eip" "this" {
  for_each = local.nat_set

  tags = merge(
    local.module_tag,
    {
      Name = "${local.vpc_name}-nat-${each.key}",
    }
  )
}

// NAT GW 생성
resource "aws_nat_gateway" "this" {
  for_each      = local.nat_set
  subnet_id     = local.subnet_ids_with_az[local.nat.subnet][each.key]
  allocation_id = aws_eip.this[each.key].id

  tags = merge(
    local.module_tag,
    {
      Name = "${local.vpc_name}-nat-${each.key}",
    }
  )

  lifecycle {
    precondition {
      condition     = split("-", local.nat.subnet)[0] == "pub"
      error_message = "[${local.vpc_name} VPC] nat.subnet으로는 퍼블릭 서브넷만 지정 가능합니다."
    }
  }
}

// Private RT -> NAT Route 추가
resource "aws_route" "private_nat" {
  for_each = local.nat.create ? local.private_rts : {}

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = aws_nat_gateway.this[element(local.nat_azs, index(local.subnet_azs, each.key) % length(local.nat_azs))].id
}