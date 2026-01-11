source "amazon-ebs" "wordpress" {
  ami_name      = "wordpress-ami-${local.timestamp}"
  instance_type = "t2.micro"
  region        = var.region
  source_ami_filter {
    filters = {
      name                = "RHEL-8.2_HVM-20200803-x86_64-0-Hourly2-GP2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["309956199498"]
  }
  ssh_username = "ec2-user"
  tags = {
    Name = "WordPress-AMI"
    Role = "WordPress"
  }
}

build {
  sources = ["source.amazon-ebs.wordpress"]

  provisioner "shell" {
    script = "wordpress.sh"
  }
}
