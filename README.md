# Automate Infrastructure With IaC using Terraform (Refactoring & Remote Backend) 

> Project Title: Automate Infrastructure With IaC using Terraform 3 (Refactoring)
>
> Level: Intermediate → Advanced
> 
> Focus: Remote Backend, State Locking, Modular Terraform Design, Dynamic Configuration

## 📌 Project Overview

This project is the third iteration in a series focused on Infrastructure as Code (IaC) using Terraform on AWS. In earlier projects, infrastructure was provisioned using Terraform with a local backend, suitable only for learning and experimentation.

In this phase, we introduce production-grade Terraform practices, including:

- Remote state management using Amazon S3
- State locking and consistency using Amazon DynamoDB
- Refactoring infrastructure into reusable Terraform modules
- Writing dynamic, scalable, and maintainable Terraform code
- Applying best practices for collaboration in DevOps teams

This project prepares the infrastructure codebase for team collaboration, scalability, and future automation.

## 🏗️ Architecture Diagram

Below is a high-level logical architecture of the infrastructure provisioned with Terraform in this project.

```pgsql
                              ┌───────────────┐
                              │   Internet    │
                              └───────┬───────┘
                                      │
                          ┌───────────▼───────────┐
                          │     External ALB       │
                          │     (Public Subnets)   │
                          └───────────┬───────────┘
                                      │
                    ┌─────────────────▼─────────────────┐
                    │        Auto Scaling Group           │
                    │      (NGINX EC2 Instances)          │
                    │           Private Subnets           │
                    └─────────────────┬─────────────────┘
                                      │
                          ┌───────────▼───────────┐
                          │      Internal ALB      │
                          │      (Private Subnets) │
                          └───────────┬───────────┘
                                      │
        ┌─────────────────────────────┼─────────────────────────────┐
        │                             │                             │
┌───────▼────────┐           ┌────────▼────────┐           ┌────────▼────────┐
│ WordPress ASG  │           │  Tooling ASG    │           │   Other Apps    │
│ Private Subnet │           │ Private Subnet  │           │ Private Subnet  │
└───────┬────────┘           └────────┬────────┘           └────────┬────────┘
        │                             │                             │
┌───────▼─────────┐         ┌─────────▼────────┐         ┌─────────▼────────┐
│   Amazon EFS    │         │    Amazon RDS    │         │   CloudWatch     │
│ Shared Storage  │         │ MySQL/Postgres   │         │ Logs & Metrics   │
└─────────────────┘         └──────────────────┘         └──────────────────┘


                 Terraform Remote State Backend
┌──────────────────────────────────────────────────────────────┐
│   S3 Bucket (Encrypted, Versioned Terraform State)            │
│   DynamoDB Table (State Locking & Consistency)                │
└──────────────────────────────────────────────────────────────┘

```

### Architecture Highlights

- Public Layer: Internet-facing ALB handles inbound HTTP/HTTPS traffic
- Private Compute Layer: EC2 instances run inside Auto Scaling Groups
- Internal Routing: Internal ALB routes traffic to WordPress and Tooling services
- Persistence: RDS for databases, EFS for shared storage
- Security: Strict Security Groups per layer
- State Management: Remote Terraform state stored securely in S3 with DynamoDB locking

## 🚀 Key Objectives

- Migrate Terraform state from local backend to S3 remote backend
- Enable state locking using DynamoDB
- Refactor infrastructure using Terraform modules
- Reduce duplication with dynamic blocks, maps, lookups, and conditional expressions
- Establish a clean, professional repository structure suitable for enterprise use

## 🧱 Why Remote Backend?

### Problems with Local Backend

- State file stored locally → not shareable
- No locking → risk of state corruption
- Not suitable for teams or CI/CD pipelines

### Solution: S3 + DynamoDB

Using S3 as a backend allows Terraform state to be:

- Centrally stored
- Versioned
- Encrypted
- Accessible by multiple engineers

### Using DynamoDB enables:

- State locking
- Prevention of concurrent writes
- Infrastructure consistency

# 🗂️ Backend Configuration

## Step 1: Create Backend resources for State (backend-resources.tf)

```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket = "princemaxi-dev-terraform-bucket"

  tags = {
    Name        = "terraform-state-bucket"
    Environment = "dev"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "terraform-locks"
    Environment = "dev"
  }
}
```

⚠️ Note: 
- S3 bucket names are globally unique. Adjust accordingly.
- Terraform requires both S3 and DynamoDB to exist before configuring the backend.

![Alt text](/image/2.png)
![Alt text](/image/3.png)
![Alt text](/image/4.png)
![Alt text](/image/1.png)

## Step 2: Configure Terraform Backend (backend.tf)

```hcl
terraform {
   backend "s3" {
     bucket         = "princemaxi-dev-terraform-bucket"
     key            = "global/terraform/terraform.tfstate"
     region         = "eu-west-2"
     dynamodb_table = "terraform-locks"
     encrypt        = true
   }
}
```

![Alt text](/image/6.png)

## Run:
```hcl
terraform init
```
Confirm backend migration when prompted.

![Alt text](/image/7.png)
![Alt text](/image/8.png)

## 🔐 State Locking Verification

1. Open DynamoDB → terraform-locks in AWS Console
![Alt text](/image/9.png)
2. Run:
   ```hcl
   terraform plan
   ```
   ![Alt text](/image/10.png)

3. Refresh DynamoDB table → observe lock entry

4. After completion → lock is released

This ensures safe collaboration across teams.

## 📤 Terraform Outputs (output.tf)

```hcl
output "s3_bucket_arn" {
value = aws_s3_bucket.terraform_state.arn
description = "The ARN of the S3 bucket"
}


output "dynamodb_table_name" {
value = aws_dynamodb_table.terraform_locks.name
description = "The name of the DynamoDB table"
}
```

![Alt text](/image/12.png)

## 🌍 Environment Isolation

Terraform supports multiple environment strategies:

### Option A: Terraform Workspaces

Best for environments with minimal differences.
```
terraform workspace new dev
terraform workspace select prod
```
### Option B: Directory-based Separation (Recommended)

Best for environments with significant configuration differences.
```
environments/
├── dev/
├── uat/
├── prod/
```

## 🔁 Refactoring with Dynamic Blocks

Dynamic blocks help eliminate repetitive configurations.

Example: Security Groups

```hcl
dynamic "ingress" {
for_each = var.ingress_rules
content {
from_port = ingress.value.from
to_port = ingress.value.to
protocol = ingress.value.protocol
cidr_blocks = ingress.value.cidr
}
}
```
![Alt text](/image/14.png)

## 🗺️ AMI Selection with Map & Lookup

```hcl
variable "images" {
type = map(string)
default = {
eu-west-2 = "ami-0abcdef"
us-east-1 = "ami-123456"
}
}

resource "aws_instance" "web" {
ami = lookup(var.images, var.region, "ami-default")
}
```
![Alt text](/image/15.png)

This ensures region-aware AMI selection.

## 🔀 Conditional Expressions

```hcl
resource "aws_db_instance" "read_replica" {
count = var.create_read_replica ? 1 : 0
replicate_source_db = aws_db_instance.primary.id
}
```
Used to conditionally create resources.

## 📦 Terraform Modules

### Modularizing Terraform for Maintainability

Instead of one large Terraform file, the infrastructure is split into logical modules:

- VPC
- Security Groups
- ALB
- Compute
- RDS
- EFS

Each module contains:

- main.tf
- variables.tf
- outputs.tf

This structure allows teams to:

- Work independently
- Reuse modules
- Scale infrastructure with minimal friction

Example

```hcl
module "network" {
source = "./modules/network"
}
```

Referencing outputs:
```hcl
subnets = module.network.public_subnets
```

![Alt text](/image/17.png)
![Alt text](/image/18.png)

## 🗃️ Project Structure: We should now have this project structure

```
PBL/
├── modules/
│ ├── ALB/
│ ├── EFS/
│ ├── RDS/
│ ├── autoscaling/
│ ├── compute/
│ ├── network/
│ └── security/
├── backend.tf
├── providers.tf
├── data.tf
├── main.tf
├── variables.tf
├── terraform.tfvars
└── outputs.tf
```
This structure supports scalable enterprise IaC.

## ⚠️ Known Limitations

- AMIs not preconfigured
- User-data scripts lack dynamic endpoints
- Website not fully functional

➡️ These will be solved using Packer, Ansible, and Terraform Cloud in future projects.


🛠️ Pro Tips

- Validate before planning:
  ```bash
  terraform validate
  ```
- Format code consistently:
  ```bash
  terraform fmt
  ```
- Make sure it works
  ```bash
  terraform plan
  terraform apply
  ```
  ![Alt text](/image/19.png)
  ![Alt text](/image/20.png)
- Confirm resources in AWS Console
  ![Alt text](/image/21.png)
  ![Alt text](/image/22.png)
  ![Alt text](/image/23.png)
  ![Alt text](/image/24.png)

---

# 📌 Conclusion

This project demonstrates how to move from basic Terraform usage to production-ready Infrastructure as Code. With remote backends, state locking, modular design, and dynamic configurations, this repository reflects real-world DevOps standards.

## 👤 Author
```
Prince Maxwell Ugochukwu
DevOps Engineer | Cloud Enthusiast | IaC Advocate
```

⭐ If this project helped you, consider starring the repository!

