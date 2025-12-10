provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "practice_vpc"
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr)
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr[count.index]
  availability_zone = var.target_azs[count.index]

  tags = {
    Name = "practice-sub-pub-${var.target_azs[count.index]}"
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidr)
  vpc_id = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr[count.index]
  availability_zone = var.target_azs[count.index]

  tags = {
    Name = "practice-sub-pri-${var.target_azs[count.index]}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "practice-igw"
  }
}

# eip
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "practice-nat-eip"
  }
}

# NAT gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "practice-nat-2a"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Table - public
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }

    tags = {
      Name = "practice-rt-public"
    }
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidr)

  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Table - private
resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_gateway.id
    }

    tags = {
      Name = "practice-rt-private"
    }
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidr)

  subnet_id = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id  
}