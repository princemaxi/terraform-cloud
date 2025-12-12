###########################################
# PRIVATE ROUTE TABLE
###########################################
resource "aws_route_table" "private_rtb" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = format("%s-private-rtb", var.name)
    }
  )
}

# Associate ALL private subnets with the private route table
resource "aws_route_table_association" "private_subnet_assoc" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rtb.id
}

###########################################
# PUBLIC ROUTE TABLE
###########################################
resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = format("%s-public-rtb", var.name)
    }
  )
}

# Default route to Internet Gateway
resource "aws_route" "public_default_route" {
  route_table_id         = aws_route_table.public_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

# Associate ALL public subnets with the public route table
resource "aws_route_table_association" "public_subnet_assoc" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rtb.id
}
