#terraform {
#   backend "s3" {
#     bucket         = "princemaxi-dev-terraform-bucket"
#     key            = "global/terraform/terraform.tfstate"
#     region         = "eu-west-2"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
#}


terraform {
  backend "remote" {
    organization = "DevOps-Palace"

    workspaces {
      name = "terraform-cloud"
    }
  }
}

