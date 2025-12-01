# 📘 Automate Infrastructure With IaC Using Terraform – Part 1

This project demonstrates how to automate provisioning of AWS infrastructure using Terraform, focusing on:

- AWS IAM configuration with programmatic access
- VPC creation
- Dynamic subnet creation
- Use of variables, data sources, and loops
- Best practices for Infrastructure as Code

This is the IaC version of the architecture previously built manually.

# 🔧 Prerequisites

Before writing Terraform code, ensure the following are set up:

## 1️⃣ Create an IAM User for Terraform

> Note: AWS removed the old “Programmatic Access** checkbox.
> 
> Now access keys must be created after the user is created.

### ✔ Step-by-step:

**Go to:**
- IAM → Users → Create User
- Enter username: 
    ```nginx
    terraform
    ```
- Do NOT enable console access *❌ Do NOT choose “Provide user access to AWS Management Console” Terraform does not need console login.*
- Permissions:
  - Choose Attach policies directly
  - Select: ✔ AdministratorAccess
- Create the user.
![alt txt](/images/1.png)
![alt txt](/images/2.png)
![alt txt](/images/3.png)
![alt txt](/images/4.png)

**Now Create Access Keys (Programmatic Access)**

- Click on the user you just created
- Go to Security credentials
- Scroll to Access Keys
- Click Create Access Key
- Select: ✔ Command Line Interface (CLI)
![alt txt](/images/5.png)
![alt txt](/images/6.png)
![alt txt](/images/7.png)

- Download or copy:
  - Access Key ID
  - Secret Access Key
  ![alt txt](/images/8.png)

These will be used for AWS CLI and Terraform authentication.

## 2️⃣ Configure AWS CLI

Install AWS CLI, then run:.
```bash
aws configure
```

**Enter:**

- Access Key ID
- Secret Access Key
- Default region (e.g., eu-central-1)
- Output format (json)

![alt txt](/images/9.png)

This creates ~/.aws/credentials, enabling Terraform to authenticate.

## 3️⃣ Install Python SDK (Optional Test)

**Install:**
```bash
pip install boto3
```
![alt txt](/images/10.png)

**Test AWS connectivity:**
```python
import boto3
s3 = boto3.resource('s3')

for bucket in s3.buckets.all():
    print(bucket.name)
```

If you see your bucket names → authentication is working.

## 4️⃣ Create an S3 Bucket for Terraform State (Used in later projects)

**Example:**
```bash
yourname-dev-terraform-bucket
```
Bucket name must be globally unique and lowercase.
![alt txt](/images/11.png)

***Note: Install Terraform if it is not yet installed locally https://developer.hashicorp.com/terraform/install***

---

# 🏗 Start Terraform Project

## Step 1 — Create Project Directory
```bash
mkdir <dir name>
cd <dir name>
```
**Create the main Terraform config file:**
```bash
touch main.tf
```
![alt txt](/images/12.png)

## Step 2 — Configure Terraform Provider

**main.tf:**
```hcl
provider "aws" {
  region = var.region
}
```

**Why not hardcode the region?**
- ❌ Hardcoding prevents reuse across environments (dev, test, prod).
- ❌ Hardcoding ties your infrastructure to one region.
- ✔ Using variables makes the project portable and scalable.

## Step 3 — Create VPC Resource
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = {
    Name = "main-vpc"
  }
}
```
![alt txt](/images/13.png)

**Why variables instead of hardcoded values?**
- Makes the configuration reusable
- Allows environment-specific values
- Makes the code maintainable and scalable
- Prevents code duplication

## Step 4 — Fetch AZs Dynamically

```hcl
data "aws_availability_zones" "available" {
  state = "available"
}
```
![alt txt](/images/14.png)

**Why dynamic AZs?**

- ✔ Avoids manually selecting AZs
- ✔ Automatically matches region changes
- ✔ Ensures high availability
- ✔ Makes code portable

## Step 5 — Create Dynamic Public Subnets
```hcl
resource "aws_subnet" "public" {
  count                   = var.preferred_number_of_public_subnets == null ? length(data.aws_availability_zones.available.names) : var.preferred_number_of_public_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}
```
![alt txt](/images/15.png)

**What this does:**
| Feature              | Why it matters                         |
| -------------------- | -------------------------------------- |
| `count`              | Creates multiple subnets automatically |
| `cidrsubnet()`       | Auto-calculates subnet CIDRs           |
| Dynamic AZ selection | No hardcoding, region-independent      |
| Variables            | Fully customizable                     |

## Step 6 — Create variables.tf
```hcl
variable "region" {
  default = "eu-west-2"
}

variable "vpc_cidr" {
  default = "172.16.0.0/16"
}

variable "enable_dns_support" {
  default = true
}

variable "enable_dns_hostnames" {
  default = true
}

variable "preferred_number_of_public_subnets" {
  default = 2
}
```
![alt txt](/images/16.png)

## Step 7 — Optional: terraform.tfvars

**Terraform automatically loads this file:**
```hcl
region                        = "eu-west-2"
vpc_cidr                      = "172.16.0.0/16"
enable_dns_support            = true
enable_dns_hostnames          = true
preferred_number_of_public_subnets = 2
```
![alt txt](/images/17.png)

## Step 8 — Initialize Terraform
```bash
terraform init
```

**This:**
  - Downloads AWS provider
  - Creates .terraform/ directory

## Step 9 — Run Terraform Plan
```bash
terraform plan
```
![alt txt](/images/18.png)
![alt txt](/images/19.png)

Shows resources Terraform will create.

## Step 10 — Apply the Configuration
```bash
terraform apply
```
![alt txt](/images/20.png)

**Type:**
```bash
yes
```
![alt txt](/images/21.png)

**Terraform creates:**

- VPC
- Dynamic public subnets
- Terraform state files

![alt txt](/images/22.png)

** Files created:**
```pgsql
terraform.tfstate
terraform.tfstate.backup
terraform.tfstate.lock.info
```

**You can confirm resources created from the AWS Management Console**
![alt txt](/images/23.png)
![alt txt](/images/24.png)

## Step 11 — Destroy Infrastructure (Optional)
```bash
terraform destroy
```
![alt txt](/images/25.png)
![alt txt](/images/26.png)

Useful during development or testing and to cut down cost when our resources are not in use.

---

###  📌 Note: Why We Did NOT Use enable_classiclink or ClassicLink DNS Support
We intentionally did NOT use ClassicLink settings because:
- AWS has fully deprecated ClassicLink.
- The AWS Terraform provider removed these arguments, so including them causes an error:
“An argument named enable_classiclink is not expected here.”
- New AWS accounts cannot enable ClassicLink, and existing ClassicLink setups are being phased out.
- Modern VPC networking and EC2 features make ClassicLink unnecessary and unsupported.

Using these deprecated fields today will break your Terraform plan/apply, so they must be excluded.

# 🎉 Conclusion

We have successfully automated AWS infrastructure using Terraform by:

- Using dynamic and scalable code
- Avoiding hardcoding
- Fetching availability zones programmatically
- Creating reusable IaC patterns
- Using AWS IAM the latest correct way