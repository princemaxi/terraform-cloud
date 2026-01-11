source "amazon-ebs" "tooling" {
  ami_name      = "tooling-ami-${local.timestamp}"
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
    Name = "Tooling-AMI"
    Role = "Tooling"
  }
}

build {
  sources = ["source.amazon-ebs.tooling"]

  provisioner "shell" {
    script = "tooling.sh"
  }
}
