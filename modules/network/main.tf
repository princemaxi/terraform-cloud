##########################################
# VPC
##########################################
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(var.tags, { Name = "${var.name}-vpc" })
}

##########################################
# Subnets
##########################################
resource "aws_subnet" "public" {
  count                   = var.preferred_number_of_public_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index * 2)
  map_public_ip_on_launch = true
  availability_zone       = var.azs[count.index % length(var.azs)]

  tags = merge(
    var.tags,
    {
      Name = format("%s-public-%02d", var.name, count.index + 1)
      Tier = "public"
    }
  )
}

resource "aws_subnet" "private" {
  count             = var.preferred_number_of_private_subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index * 2 + 1)
  availability_zone = var.azs[count.index % length(var.azs)]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name = format("%s-private-%02d", var.name, count.index + 1)
      Tier = "private"
    }
  )
}

##########################################
# Internet Gateway
##########################################
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, { Name = "${var.name}-ig" })
}

##########################################
# NAT Gateway
##########################################
resource "aws_eip" "nat_eip" {
  count = 1

  tags = merge(var.tags, { Name = "${var.name}-nat-eip" })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip[0].id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [aws_internet_gateway.ig]

  tags = merge(var.tags, { Name = "${var.name}-nat" })
}

##########################################
# Public Route Table
##########################################
resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }

  tags = merge(var.tags, { Name = "${var.name}-public-rtb" })
}

resource "aws_route_table_association" "public_subnet_assoc" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rtb.id
}

##########################################
# Private Route Table
##########################################
resource "aws_route_table" "private_rtb" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(var.tags, { Name = "${var.name}-private-rtb" })
}

resource "aws_route_table_association" "private_subnet_assoc" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rtb.id
}
