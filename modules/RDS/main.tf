##########################################
# Subnet Group
##########################################
resource "aws_db_subnet_group" "acs_rds" {
  name       = "acs-rds"
  subnet_ids = [for id in var.private_subnets : id]

  tags = merge(
    var.tags,
    { Name = "ACS-rds" }
  )
}

##########################################
# RDS Instance
##########################################
resource "aws_db_instance" "acs_rds" {
  allocated_storage    = var.allocated_storage
  storage_type         = var.storage_type
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  db_name              = var.db_name
  username             = var.master_username
  password             = var.master_password
  parameter_group_name = "default.mysql5.7"

  db_subnet_group_name   = aws_db_subnet_group.acs_rds.name
  vpc_security_group_ids = [var.datalayer_sg_id]

  multi_az            = var.multi_az
  skip_final_snapshot = true
}
