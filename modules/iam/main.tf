##########################################
# IAM Role for EC2
##########################################
resource "aws_iam_role" "ec2_instance_role" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

##########################################
# IAM Policy
##########################################
resource "aws_iam_policy" "ec2_policy" {
  name        = var.policy_name
  description = "Allow EC2 describe access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ec2:Describe*"]
      Resource = "*"
    }]
  })

  tags = var.tags
}

##########################################
# Attach Policy to Role
##########################################
resource "aws_iam_role_policy_attachment" "ec2_attach" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

##########################################
# IAM Instance Profile
##########################################
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = var.instance_profile_name
  role = aws_iam_role.ec2_instance_role.name
}
