// =====
// A. VPC 생성
locals {
  vpc_id = aws_vpc.this.id
  vpc_name = var.name
  vpc_cidr = var.attribute.cidr
  
  module_tag = merge(
    var.tags, // 각 환경 별 공통적용태그
    {
      tf_module = "vpc"
      Env = var.attribute.env
      Team = var.attribute.Team
      VPC = "${local.vpc_name}-vpc"
    }
  )
}

resource "aws_vpc" "this" {
  cidr_block = local.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = merge(
    local.module_tag,
    {
      Name = "${local.vpc_name}-vpc"
    }
  )
}

// =====
// B. 서브넷 라우터 생성

// [Public Subnet Router] -> Public Subnet이 존재하는 경우에만 실행
// 1) 퍼블릭 서브넷 존재여부 체크
locals { 
    subnets = var.attribute.subnets

    enable_igw = anytrue(
      [for k, v in local.subnets : split("-". k)[0] == "pub"]
    )
}

// 2) IGW 생성
resource "aws_internet_gateway" "this" {
  count = local.enable_igw ? 1 : 0
  vpc_id = local.vpc_id

  tags = merge(
    local.module_tag,
    {
      Name = "${local.vpc_name}-igw"
    }
  )
}

// 3) Public Route Table 생성
resource "aws_route_table" "public" {
  count = local.enable_igw ? 1 : 0
  vpc_id = local.vpc_id

  tags = merge(
    local.module_tag,
    {
      Name = "${local.vpc_name}-rt-pub"
    }
  )
}

// 4) IGW에 Route Table 설정
resource "aws_route" "public_igw" {
  count = local.enable_igw ? 1 : 0

  destination_cidr_block = "0.0.0.0/0"
  route_table_id = aws_route_table.public[count.index].id
  gateway_id = aws_internet_gateway.this[count.index].id
}

// [Private Subnet Router]
locals {
  subnet_azs = var.attribute.subnet_azs
}

resource "aws_route_table" "private" {
  for_each = toset(local.subnet_azs)
  vpc_id = local.vpc_id

  tags = merge(
    local.module_tag,
    {
      Name = "${local.vpc_name}-rt-pri-${each.value}"
    }
  )
}

// =====
// C. 서브넷 생성

// 1) 입력값 구조화
locals {
  subnet_newbits =var.attribute.subnet_newbits
  subnet_azs = var.attribute.subnet_azs
  subnets = var.attribute.subnets

  subnets_data = flatten([
    for name, indices in local.subnets: [
      for idx in indices : {
        name = name
        az = local.subnet_azs[index(indices, idx)]
        cidr = cidrsubnet(local.vpc_cidr, local.subnet_newbits, idx)
        is_public = split("-", name)[0] == "pub"
      }
    ]
  ])

  subnets_map = {
    for s in local.subnets_data : "${replace(s.name, "-", "_")}_${s.az}" => s
  }
}

// 2) 서브넷 생성
module "current" {
  source = "../utility/get_aws_metadata"
}

locals {
  region_name = module.curent.region_name
}

resource "aws_subnet" "this" {
  for_each = local.subnets_map
  cidr_block = each.value.cidr
  availability_zone = "${local.region_name}${each.value.az}"
  vpc_id = local.vpc_id
  map_public_ip_on_launch = each.value.is_public

  tags = merge(
    local.module_tag,
    {
      Name = "${local.vpc_name}-subnet-${each.value.name}-${each.value.az}"
    }
  )
}

// 3) 서브넷-라우터 연결
locals {
  public_rt = try(aws_route_table.public[0].id, "")
  private_rts = {
    for k, v in aws_aws_route_table.private : k => v.id
  }
}

resource "aws_route_table_association" "this" {
  for_each = local.subnets_map
  route_table_id = each.value.is_public ? local.public_rt : local.private_rts[each.value.az]
  subnet_id = aws_subnet.this[each.key].id
}

locals {
  subnet_ids = {
    for k, v in local.subnets : k => [
      for az in slice(local.subnet_azs, 0, length(v)) : aws_subnet.this["${replace(k, "-", "_")}_${az}"].id
    ]
  }

  subnet_ids_with_az = {
    for k, v in local.subnets : k => {
      for az in slice(local.subnet_azs, 0, length(v)) : az => aws_subnet.this["${replace(k, "-", "_")}_${az}"].id
    }
  }
}