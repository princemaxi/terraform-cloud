##########################################
# KMS Key & Alias
##########################################
resource "aws_kms_key" "acs_kms" {
  description = "KMS key for EFS encryption"
  deletion_window_in_days = 7  # Minimum is 7 days, maximum is 30

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "Enable IAM User Permissions"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${var.account_no}:user/terraform"
      }
      Action   = "kms:*"
      Resource = "*"
    }]
  })
}

resource "aws_kms_alias" "acs_kms_alias" {
  name          = "alias/acs-kms"
  target_key_id = aws_kms_key.acs_kms.key_id
}

##########################################
# EFS File System
##########################################
resource "aws_efs_file_system" "acs_efs" {
  encrypted  = true
  kms_key_id = aws_kms_key.acs_kms.arn

  tags = merge(var.tags, { Name = "ACS-efs" })
}

##########################################
# Lookup subnets (needed for AZ)
##########################################
data "aws_subnet" "private" {
  for_each = toset(var.private_subnets)
  id       = each.value
}

##########################################
# One subnet per AZ (CRITICAL FIX)
##########################################
locals {
  subnets_by_az = {
    for s in data.aws_subnet.private :
    s.availability_zone => s.id...
  }

  one_subnet_per_az = {
    for az, ids in local.subnets_by_az :
    az => ids[0]
  }
}

##########################################
# EFS Mount Targets (ONE PER AZ)
##########################################
resource "aws_efs_mount_target" "mt" {
  for_each = local.one_subnet_per_az

  file_system_id  = aws_efs_file_system.acs_efs.id
  subnet_id       = each.value
  security_groups = [var.efs_sg_id]
}

##########################################
# EFS Access Points
##########################################
resource "aws_efs_access_point" "wordpress" {
  file_system_id = aws_efs_file_system.acs_efs.id

  root_directory {
    path = "/wordpress"
    creation_info {
      owner_uid   = 0
      owner_gid   = 0
      permissions = "0755"
    }
  }
}

resource "aws_efs_access_point" "tooling" {
  file_system_id = aws_efs_file_system.acs_efs.id

  root_directory {
    path = "/tooling"
    creation_info {
      owner_uid   = 0
      owner_gid   = 0
      permissions = "0755"
    }
  }
}
