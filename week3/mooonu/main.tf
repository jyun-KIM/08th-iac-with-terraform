provider "aws" {
  region = "ap-northeast-2"
}

# vpc
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "practice_vpc"
  }
}

# subnet1
resource "aws_subnet" "public_2a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "practice-sub-pub-2a"
  }
}

# subnet2
resource "aws_subnet" "public_2c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "practice-sub-pub-2c"
  }
}

# subnet3
resource "aws_subnet" "private_2a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "practice-sub-pri-2a"
  }
}

# subnet4
resource "aws_subnet" "private_2c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "practice-sub-pri-2c"
  }
}

# igw
resource "aws_internet_gateway" "igw" {
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
  subnet_id     = aws_subnet.public_2a.id

  tags = {
    Name = "practice-nat-2a"
  }
}

# Route Table - public
resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
      Name = "practice-sub-pub-rt"
    }
}

resource "aws_route_table_association" "public_rt_assoc_2a" {
  subnet_id = aws_subnet.public_2a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_assoc_2c" {
  subnet_id = aws_subnet.public_2c.id
  route_table_id = aws_route_table.public_rt.id
}

# Route Table - private
resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_gateway.id
    }

    tags = {
      Name = "practice-sub-pri-rt"
    }
}

resource "aws_route_table_association" "private_rt_assoc_2a" {
  subnet_id = aws_subnet.private_2a.id
  route_table_id = aws_route_table.private_rt.id  
}

resource "aws_route_table_association" "private_rt_assoc_2c" {
  subnet_id = aws_subnet.private_2c.id
  route_table_id = aws_route_table.private_rt.id  
}