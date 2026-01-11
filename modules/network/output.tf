##########################################
# VPC
##########################################
output "vpc_id" {
  value = aws_vpc.main.id
}

##########################################
# Subnet IDs (lists)
##########################################
output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

##########################################
# Subnets by AZ (CRITICAL OUTPUTS)
##########################################
output "public_subnets_by_az" {
  description = "Map of AZ → public subnet ID (one per AZ)"
  value = {
    for az in distinct(aws_subnet.public[*].availability_zone) :
    az => aws_subnet.public[
      index(aws_subnet.public[*].availability_zone, az)
    ].id
  }
}

output "private_subnets_by_az" {
  description = "Map of AZ → private subnet ID (one per AZ)"
  value = {
    for az in distinct(aws_subnet.private[*].availability_zone) :
    az => aws_subnet.private[
      index(aws_subnet.private[*].availability_zone, az)
    ].id
  }
}
