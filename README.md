# Automate Infrastructure With IaC using Terraform — Project 201

complete guide to building production-ready AWS infrastructure using Terraform, including:

- VPC and Networking
- Public and Private Subnets
- NAT Gateway & Internet Gateway
- Security Groups
- Application Load Balancer
- EC2 (Nginx + Bastion + Tooling + WordPress)
- RDS MySQL
- Route53 (optional)
- Fully modular and well-structured Terraform code
- Reusable tagging strategy
- Best practices for IaC consistency and maintainability

This documentation is designed to help anyone reproduce this infrastructure — from beginner to professional DevOps engineer.

## Project Overview

This project continues from “Automate Infrastructure with IaC Using Terraform — Project 101” and expands the infrastructure into a more advanced, production-like architecture.

In this phase, we implement:

- ✔️ Better code structure
- ✔️ Improved variable usage
- ✔️ Dynamic resource creation using count and length()
- ✔️ Subnet automation using cidrsubnet()
- ✔️ Centralized tagging using merge()
- ✔️ Private-only workloads
- ✔️ Secure RDS
- ✔️ ALB routing to Nginx
- ✔️ Automated EC2 configuration using user_data scripts
- ✔️ Separate .tf files for readability

This README provides a complete, step-by-step guide, so you can recreate the infrastructure exactly as designed.

```css
├── main.tf
├── internet_gateway.tf
├── natgateway.tf
├── security.tf
├── route_tables.tf
├── alb.tf
├── roles.tf
├── asg-bastion-nginx.tf
├── asg-wordpress-tooling.tf
├── rds.tf
├── efs.tf
├── variables.tf
├── outputs.tf
├── userdata/
│   ├── nginx.sh
│   ├── wordpress.sh
│   ├── tooling.sh
│   └── bastion.sh
├── terraform.tfvars
├── .gitignore
├── .gitattributes
└── README.md
```

## Prerequisites

Before deploying this project, ensure you have:

### Tools:

- Terraform v1.3+
- AWS CLI v2
- Git
- A Unix-friendly terminal (Git Bash or WSL recommended on Windows)
- An IDE (e.g VS code)

### AWS Requirements

**An IAM user with programmatic access**

**Permissions:**

- VPC
- EC2
- RDS
- Load Balancers
- CloudWatch Logs
- IAM Role creation (for EC2)

## Project Features
| Feature                                  | Description                                       |
| ---------------------------------------- | ------------------------------------------------- |
| **Modular, Clean Terraform Code**        | Follows best practices and separation of concerns |
| **4 Private Subnets (Dynamic)**          | Automatically created based on AZ count           |
| **Dynamic Tagging System**               | Centralized tags using `merge()`                  |
| **Secure RDS Deployment**                | Private-only, no public access                    |
| **Multiple EC2 Instances**               | Nginx, Bastion, WordPress, Tooling                |
| **ALB + Target Groups**                  | For load balancing to Nginx EC2                   |
| **User Data Automation**                 | Servers install software automatically at launch  |
| **Scalable (Easily Add More Resources)** | Structure supports growth                         |

## Tagging Strategy

We use a centralized tag object and merge it with resource-specific tags:

```nginx
tags = merge(
  var.tags,
  {
    Name = "resource-name"
  }
)
```
**This ensures: Consistency, Easy changes, Better billing visibility and Clear ownership**

---

# Implementation Guide

## Networking Phase

## Step 1 — Create Private Subnets

In this phase, we automatically create multiple private subnets using Terraform added to `main.tf`.
The configuration is dynamic, scalable, and follows best practices.

```hcl
resource "aws_subnet" "private" {
  count                   = var.preferred_number_of_private_subnets == null ? length(data.aws_availability_zones.available.names) : var.preferred_number_of_private_subnets
  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.azs[floor(count.index / 2)]
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index * 2 + 1)
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name = format("private-subnet-%02d", count.index + 1)
      Tier = "private"
    }
  )
}
```

### Code — Explanation
- `count` → Defines how many subnets to create, based on user input or number of AZs.
- `availability_zone` → Spreads subnets evenly across AZs for high availability.
- `cidrsubnet()` → Automatically generates unique, non-overlapping CIDR blocks.
- `map_public_ip_on_launch = false` → Ensures the subnet is private.
- `tags` + `format()` → Gives each subnet a clean, unique name (e.g., `private-subnet-01`, `private-subnet-02`) while merging default tags for consistency.

## Step 2 — Create Internet Gateway 

`internet_gateway.tf`
```hcl
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = format("%s-%s", aws_vpc.main.id, "IG")
    }
  )
}
```

### Code — Explanation
- Creates an Internet Gateway (IGW) and attaches it to the main VPC so public subnets can reach the internet.
- `vpc_id` links the IGW directly to the VPC.
- `merge()` applies both global tags and IGW-specific tags.
- `format()` automatically generates a clean, unique name using the VPC ID (e.g., vpc-12345-IG).

## Step 3 — Create NAT Gateway Setup (natgateway.tf)
The NAT Gateway allows private subnets to access the internet without exposing them publicly.
We create one Elastic IP (EIP) and one NAT Gateway, both depending on the Internet Gateway.

**Elastic IP for NAT Gateway**
```hcl
resource "aws_eip" "nat_eip" {
  depends_on = [
    aws_internet_gateway.ig
  ]

  tags = merge(
    var.tags,
    {
      Name = format("%s-eip", var.name)
    }
  )
}
```

### Purpose:
- Allocates a static public IP to attach to the NAT Gateway.
- `depends_on` ensures the Internet Gateway exists before the EIP is created.
- Tagging uses `format()` to generate consistent naming.

**NAT Gateway**
```hcl
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id  # first public subnet

  depends_on = [
    aws_internet_gateway.ig
  ]

  tags = merge(
    var.tags,
    {
      Name = format("%s-nat", var.name)
    }
  )
}
```

### Purpose:
- Provides outbound internet access for private subnets.
- Placed in the **first public subnet**.
- Inherits consistent organization-wide tags.

## Step 4 — Create Route Tables (route_tables.tf)
```hcl
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
```

### ✅ What This File Does
- Private Route Table
  - Routes internal traffic
  - Subnets use NAT Gateway (you will add that route separately)
  - All private subnets get associated
- Public Route Table
  - Has a default route to Internet Gateway
  - All public subnets get associated
  - This gives them direct internet access


## AWS Identity and Access Management (IAM) and Roles Phase

### 📌 Step 1. Create an IAM Role for EC2 (AssumeRole)

The EC2 service must assume a role to obtain temporary credentials through STS.
This role defines who can assume it — in this case, EC2.
```hcl
resource "aws_iam_role" "ec2_instance_role" {
  name = "ec2_instance_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, {
    Name = "aws-assume-role"
  })
}
```

### 📌 2. Create a Custom IAM Policy

This policy defines what the EC2 instance is allowed to do. For this project, we allow the instance to describe EC2 resources.
```hcl
resource "aws_iam_policy" "ec2_policy" {
  name        = "ec2_instance_policy"
  description = "Allow EC2 to describe instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ec2:Describe*"]
      Resource = "*"
    }]
  })

  tags = merge(var.tags, {
    Name = "aws-ec2-policy"
  })
}
```

### 📌Step 3. Attach the IAM Policy to the Role

This links the policy to the role so EC2 can perform the defined actions.
```hcl
resource "aws_iam_role_policy_attachment" "ec2_attach" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}
```

### 📌Step 4. Create an IAM Instance Profile

EC2 instances cannot use an IAM role directly —
they must use an instance profile that contains the role.
```hcl
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_instance_role.name

  tags = merge(var.tags, {
    Name = "ec2_instance_profile"
  })
}
```

**You will reference this in your EC2 configuration:**
```hcl
iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
```

### In this phase, we created:
| Resource              | Purpose                                |
| --------------------- | -------------------------------------- |
| **IAM Role**          | Allows EC2 to assume a secure identity |
| **IAM Policy**        | Defines what EC2 is allowed to do      |
| **Policy Attachment** | Connects the policy to the role        |
| **Instance Profile**  | Required wrapper used by EC2           |

## 🚀 Security Groups (Network Firewalls for the Infrastructure)

Security Groups act as virtual firewalls for AWS resources.
In this phase, we define all required Security Groups in a single file: security.tf.

Each Security Group controls:

- Allowed ingress traffic (inbound)
- Allowed egress traffic (outbound)
- Which resource can communicate with which
- Layered security across ALBs, Bastion, Nginx, Webservers, and the Data layer

All SGs follow the same best practices:

- ✔ Principle of least privilege
- ✔ Clear separation between layers
- ✔ Explicit rule creation using aws_security_group_rule
- ✔ Standardized tagging using merge(var.tags, … )

### 🔐 Security Groups Overview
| Security Group   | Purpose        | Allows Traffic From    |
| ---------------- | -------------- | ---------------------- |
| **ext-alb-sg**   | External ALB   | Internet (0.0.0.0/0)   |
| **bastion-sg**   | Bastion host   | Internet (SSH)         |
| **nginx-sg**     | Nginx EC2      | ALB + Bastion          |
| **int-alb-sg**   | Internal ALB   | Nginx                  |
| **webserver-sg** | Web servers    | Internal ALB + Bastion |
| **datalayer-sg** | Database & EFS | Webservers + Bastion   |

This ensures a secure multi-tier architecture.

### 📄 security.tf

Below is the complete Security Group configuration:

### Step 1. External ALB Security Group

**Allows HTTP from the internet.**
```hcl
resource "aws_security_group" "ext_alb_sg" {
  name        = "ext-alb-sg"
  description = "Allow HTTP from anywhere"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "ext-alb-sg" })
}
```

### Step 2. Bastion Host Security Group

**Allows SSH from anywhere (best for testing; restrict in production).**
```hcl
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH from anywhere"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "bastion-sg" })
}
```

### Step 3. Nginx Security Group

**Allows traffic only from the ALB (HTTP) and Bastion (SSH).**
```hcl
resource "aws_security_group" "nginx_sg" {
  name        = "nginx-sg"
  description = "Allow traffic from ALB and Bastion"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "nginx-sg" })
}
```

**Rules**
```hcl
resource "aws_security_group_rule" "nginx_http_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.nginx_sg.id
  source_security_group_id = aws_security_group.ext_alb_sg.id
}

resource "aws_security_group_rule" "nginx_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.nginx_sg.id
  source_security_group_id = aws_security_group.bastion_sg.id
}
```

### Step 4. Internal ALB Security Group

**Accepts HTTP traffic only from Nginx.**
```hcl
resource "aws_security_group" "int_alb_sg" {
  name        = "int-alb-sg"
  description = "Allow traffic only from Nginx"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "int-alb-sg" })
}
```

**Rule**
```hcl
resource "aws_security_group_rule" "int_alb_http_from_nginx" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.int_alb_sg.id
  source_security_group_id = aws_security_group.nginx_sg.id
}
```

### Step 5. Webserver Security Group

**Allows HTTP from internal ALB and SSH from Bastion.**
```hcl
resource "aws_security_group" "webserver_sg" {
  name        = "webserver-sg"
  description = "Allow traffic from internal ALB and Bastion"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "webserver-sg" })
}
```

**Rules**
```hcl
resource "aws_security_group_rule" "web_http_from_int_alb" {
  type = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  security_group_id = aws_security_group.webserver_sg.id
  source_security_group_id = aws_security_group.int_alb_sg.id
}

resource "aws_security_group_rule" "web_ssh_from_bastion" {
  type = "ingress"
  from_port = 22
  to_port   = 22
  protocol  = "tcp"
  security_group_id = aws_security_group.webserver_sg.id
  source_security_group_id = aws_security_group.bastion_sg.id
}
```

### Step 6. Data Layer Security Group (DB + EFS)

**Allows MySQL and NFS traffic only from allowed tiers.**
```hcl
resource "aws_security_group" "datalayer_sg" {
  name        = "datalayer-sg"
  description = "Allow traffic from webservers and Bastion"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "datalayer-sg" })
}
```

**Rules**
```hcl
resource "aws_security_group_rule" "datalayer_nfs_from_web" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.datalayer_sg.id
  source_security_group_id = aws_security_group.webserver_sg.id
}

resource "aws_security_group_rule" "datalayer_mysql_from_bastion" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.datalayer_sg.id
  source_security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "datalayer_mysql_from_web" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.datalayer_sg.id
  source_security_group_id = aws_security_group.webserver_sg.id
}
```

At this point, you have a complete multi-tier firewall architecture protecting:

- Public Layer
- Bastion Layer
- Reverse Proxy Layer
- Internal ALB
- Application Layer
- Database Layer

Your infrastructure is now secure and production-grade.

## 🚀 Application Load Balancers (ALB) Setup Phase

In this phase, we provision both external (internet-facing) and internal (private) ALBs, create Target Groups, and configure Listeners.
All ALB resources are defined in `alb.tf`.

Application Load Balancers help:

- Distribute traffic across multiple EC2 instances
- Increase fault tolerance
- Enable path-based routing
- Separate public and private traffic layers

### Step 1. External ALB (Internet-facing)

The external ALB handles public traffic from the internet and forwards it to Nginx EC2 instances.
```hcl
resource "aws_lb" "ext_alb" {
  name               = "ext-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ext_alb_sg.id]
  subnets            = [aws_subnet.public[0].id, aws_subnet.public[1].id]

  ip_address_type = "ipv4"

  tags = merge(var.tags, { Name = "ACS-ext-alb" })
}
```

### Step 2. Target Group for External ALB

The target group defines the EC2 instances the ALB routes traffic to.
```hcl
resource "aws_lb_target_group" "nginx_tgt" {
  name        = "nginx-tgt"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    path                = "/healthstatus"
    protocol            = "HTTP"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.tags, { Name = "nginx-tgt" })
}
```

### Step 3. Listener for External ALB

The listener forwards all HTTP traffic to the Nginx target group.
```hcl
resource "aws_lb_listener" "nginx_listener" {
  load_balancer_arn = aws_lb.ext_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_tgt.arn
  }
}
```

### Step 4. Internal ALB (Private)

The internal ALB handles traffic within the VPC for application workloads like WordPress and Tooling.
```hcl
resource "aws_lb" "int_alb" {
  name               = "int-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.int_alb_sg.id]
  subnets            = [aws_subnet.private[0].id, aws_subnet.private[2].id]

  ip_address_type = "ipv4"

  tags = merge(var.tags, { Name = "ACS-int-alb" })
}
  ```

### Step 5. Target Groups for Internal ALB

- WordPress Target Group
    ```hcl
    resource "aws_lb_target_group" "wordpress_tgt" {
      name        = "wordpress-tgt"
      port        = 80
      protocol    = "HTTP"
      target_type = "instance"
      vpc_id      = aws_vpc.main.id

      health_check {
        path                = "/healthstatus"
        protocol            = "HTTP"
        interval            = 10
        timeout             = 5
        healthy_threshold   = 5
        unhealthy_threshold = 2
      }
    }
    ```

- Tooling Target Group
```hcl
resource "aws_lb_target_group" "tooling_tgt" {
  name        = "tooling-tgt"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    path                = "/healthstatus"
    protocol            = "HTTP"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}
```

### Step 6. Listener for Internal ALB

The internal ALB listener forwards HTTP traffic to the WordPress target group by default.
```hcl
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.int_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress_tgt.arn
  }
}
```

### Step 7. Listener Rule for Tooling

Routes `/tooling*` paths to the Tooling target group.
```hcl
resource "aws_lb_listener_rule" "tooling" {
  listener_arn = aws_lb_listener.web_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tooling_tgt.arn
  }

  condition {
    path_pattern {
      values = ["*/tooling*"]
    }
  }
}
```

### ✅ Key Takeaways

- External ALB → Public-facing → Routes traffic to Nginx
- Internal ALB → Private → Routes traffic to WordPress & Tooling
- Target groups allow health checks and load distribution
- Listener rules enable path-based routing without a domain
- All resources are tagged consistently using merge(var.tags, …)

## 🚀 Auto Scaling Groups (ASG) Setup Phase

In this phase, we configure Auto Scaling Groups for all EC2 layers — Bastion, Nginx, WordPress, and Tooling servers — so that instances can scale dynamically based on traffic.

We also configure Launch Templates, SNS notifications, and ASG attachments to ALBs.
All resources are split into two Terraform files for better structure:

- `asg-bastion-nginx.tf`
- `asg-wordpress-tooling.tf`

### Step 1. SNS Topic for Auto Scaling Notifications

We create a single SNS topic to receive notifications on instance launches, terminations, and errors across all ASGs.
```hcl
resource "aws_sns_topic" "asg_notifications" {
  name = "default-autoscaling-topic"
}

resource "aws_autoscaling_notification" "asg_events" {
  group_names = [
    aws_autoscaling_group.bastion_asg.name,
    aws_autoscaling_group.nginx_asg.name,
    aws_autoscaling_group.wordpress_asg.name,
    aws_autoscaling_group.tooling_asg.name
  ]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.asg_notifications.arn
}
```

### Step 2. Randomized AZ Distribution
```hcl
resource "random_shuffle" "az_list" {
  input = data.aws_availability_zones.available.names
}
```
Randomizes availability zones to ensure high availability across the region.

### Step 3. Launch Templates

Launch Templates define the configuration for instances in each ASG:

- AMI: We use a placeholder AMI for now; later, we will use a custom Packer-built AMI.
- Security Group: Associates the correct security group per instance type.
- IAM Instance Profile: Assigns the EC2 role.
- User Data: Script executed on boot (bastion.sh, nginx.sh, etc.)
- Tags: Each instance is uniquely tagged.

Example: **Bastion Launch Template**
```hcl
resource "aws_launch_template" "bastion_lt" {
  name_prefix   = "bastion-lt-"
  image_id      = var.ami
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ip.id
  }

  key_name = var.keypair

  placement {
    availability_zone = random_shuffle.az_list.result[0]
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "bastion-instance" })
  }

  user_data = filebase64("${path.module}/bastion.sh")

  lifecycle {
    create_before_destroy = true
  }
}
```
All other launch templates follow the same pattern for Nginx, WordPress, and Tooling.

### Step 4. Auto Scaling Groups (ASG)

Each ASG defines:

- Minimum, Maximum, and Desired Capacity
- VPC Subnets
- Health check type (EC2 or ELB)
- Launch Template
- Tags propagated at launch

Example: **Nginx ASG**
```hcl
resource "aws_autoscaling_group" "nginx_asg" {
  name                 = "nginx-asg"
  max_size             = 2
  min_size             = 1
  desired_capacity     = 1
  health_check_type    = "ELB"
  health_check_grace_period = 300

  vpc_zone_identifier = [
    aws_subnet.public[0].id,
    aws_subnet.public[1].id
  ]

  launch_template {
    id      = aws_launch_template.nginx_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "nginx-instance"
    propagate_at_launch = true
  }
}
```
Similarly, ASGs are created for **Bastion**, **WordPress**, and **Tooling**.

### Step 5. Attach ASGs to Load Balancers

Each ASG is attached to the appropriate Target Group for load balancing:
```hcl
resource "aws_autoscaling_attachment" "nginx_attach" {
  autoscaling_group_name = aws_autoscaling_group.nginx_asg.id
  lb_target_group_arn    = aws_lb_target_group.nginx_tgt.arn
}
```

- **Bastion** ASG → Not attached to ALB (direct SSH access)
- **Nginx** ASG → External ALB
- **WordPress** ASG → Internal ALB
- **Tooling** ASG → Internal ALB

### ✅ Key Takeaways

- Launch templates standardize instance configurations across ASGs.
- Auto Scaling Groups scale EC2 instances dynamically based on traffic or manual configuration.
- SNS notifications allow monitoring of ASG events.
- Attachments to ALBs ensure that instances are automatically registered with the correct target groups.
- Randomized AZ distribution improves high availability and fault tolerance.

## 🚀 Storage & Database Layer Phase

In this phase, we implement the data layer of the architecture, which consists of:

- KMS → Key management and EFS encryption
- EFS → Shared, scalable file storage for WordPress + Tooling
- RDS MySQL → Managed relational database engine

This phase ensures secure, persistent, and scalable storage across components.

### 📌Step 1. Create Elastic File System (EFS)

Before provisioning EFS, you must create a KMS Key to encrypt the file system at rest.

Create file: efs.tf

### 1.1 Create KMS Key

The KMS key controls encryption for EFS.
Access is granted to the `terraform` IAM user via a key policy.
```hcl
resource "aws_kms_key" "acs_kms" {
  description = "KMS key for EFS encryption"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "kms-key-policy",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": { 
        "AWS": "arn:aws:iam::${var.account_no}:user/terraform"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
EOF
}
```

### 1.2 Create KMS Alias

Human-readable alias for the key.
```hcl
resource "aws_kms_alias" "acs_kms_alias" {
  name          = "alias/acs-kms"
  target_key_id = aws_kms_key.acs_kms.key_id
}
```

### 1.3 Create EFS File System

Encrypted using the KMS key.
```hcl
resource "aws_efs_file_system" "acs_efs" {
  encrypted   = true
  kms_key_id  = aws_kms_key.acs_kms.arn

  tags = merge(
    var.tags,
    { Name = "ACS-efs" }
  )
}
```

### 1.4 EFS Mount Targets

Mount targets must be created in each private subnet that EC2s run in.
```hcl
resource "aws_efs_mount_target" "mt1" {
  file_system_id = aws_efs_file_system.acs_efs.id
  subnet_id      = aws_subnet.private[0].id
  security_groups = [aws_security_group.datalayer_sg.id]
}

resource "aws_efs_mount_target" "mt2" {
  file_system_id = aws_efs_file_system.acs_efs.id
  subnet_id      = aws_subnet.private[2].id
  security_groups = [aws_security_group.datalayer_sg.id]
}
```

### 1.5 EFS Access Points

Access points provide isolated directory paths for different applications.

**WordPress Access Point**
```hcl
resource "aws_efs_access_point" "wordpress" {
  file_system_id = aws_efs_file_system.acs_efs.id

  posix_user {
    gid = 0
    uid = 0
  }

  root_directory {
    path = "/wordpress"

    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = 0755
    }
  }
}
```

**Tooling Access Point**
```hcl
resource "aws_efs_access_point" "tooling" {
  file_system_id = aws_efs_file_system.acs_efs.id

  posix_user {
    gid = 0
    uid = 0
  }

  root_directory {
    path = "/tooling"

    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = 0755
    }
  }
}
```

### 🔷Step 2. Create MySQL RDS Database

Create file: `rds.tf`

RDS is used by the WordPress and Tooling applications.

### 2.1 RDS Subnet Group

RDS requires private subnets across two AZs for Multi-AZ deployment.
```hcl
resource "aws_db_subnet_group" "acs_rds" {
  name       = "acs-rds"
  subnet_ids = [
    aws_subnet.private[0].id,
    aws_subnet.private[2].id
  ]

  tags = merge(
    var.tags,
    { Name = "ACS-rds" }
  )
}
```

### 2.2 Create RDS Instance

Fully managed MySQL database, HA enabled.
```hcl
resource "aws_db_instance" "acs_rds" {
  allocated_storage      = 20
  storage_type           = "gp2"

  engine                 = "mysql"
  engine_version         = "5.7"

  instance_class         = "db.t3.small"

  db_name                = "maxidb"
  username               = var.master-username
  password               = var.master-password

  parameter_group_name   = "default.mysql5.7"

  db_subnet_group_name   = aws_db_subnet_group.acs_rds.name
  vpc_security_group_ids = [aws_security_group.datalayer_sg.id]

  multi_az               = true
  skip_final_snapshot    = true
}
```

By completing this phase, we now have:

🔐 **KMS**
- Custom-managed encryption key
- Alias for easy identification
- Used to encrypt EFS

📂 **EFS**
- Highly available, scalable file system
- Mount targets in 2 private subnets
- Access points for WordPress and Tooling

🗄️ **RDS MySQL**
- Multi-AZ high-availability database
- Private subnets only
- Secure with datalayer security group

This completes the data storage layer of our infrastructure.

## EC2 User Data Configuration Phase

In this phase, we configure User Data scripts that automatically install and configure required software on EC2 instances at launch. These scripts enable servers to self-provision without manual setup.

We will create four User Data files, each dedicated to a specific server role inside our architecture:
- Bastion Host
- Nginx Reverse Proxy
- Tooling Application Server
- WordPress Application Server

These files should be stored inside a folder such as:
```bash
/userdata
```

### 3.1 Bastion Host User Data — `bastion.sh`

Used to prepare the jump server with tools like Git and Ansible.
```bash
#!/bin/bash
yum update -y
yum install ansible git -y
```

### 3.2 Nginx Reverse Proxy User Data — `nginx.sh`

Installs and configures Nginx, then starts the service automatically.
```bash
#!/bin/bash
yum update -y
yum install nginx -y
systemctl enable nginx
systemctl start nginx
```

### 3.3 Tooling Application Server User Data — `tooling.sh`

Sets up Apache + PHP and deploys a simple Tooling webpage.
```bash
#!/bin/bash
yum update -y
yum install httpd php -y
systemctl enable httpd
systemctl start httpd
echo "Tooling Website" > /var/www/html/index.html
```

### 3.4 WordPress Server User Data — `wordpress.sh`

Installs Apache, PHP, MySQL client, then downloads and configures WordPress.
```bash
#!/bin/bash
yum update -y

# install web + php + mysql client
yum install -y httpd php php-mysqlnd php-fpm php-cli mariadb105-client wget

# start apache
systemctl enable httpd
systemctl start httpd

# download wordpress
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz -C /var/www/html --strip-components=1

# permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# restart apache
systemctl restart httpd
```

## Variable Declaration Validation

During implementation, several variables were referenced across multiple Terraform files (VPC, Auto Scaling Groups, Launch Templates, EFS, KMS, and RDS). These variables must be explicitly declared in the variables.tf file to ensure successful execution.

After reviewing the entire codebase, the complete `variables.tf` file should appear as follows:

`variables.tf`
```hcl
variable "region" {
  type        = string
  description = "The region to deploy resources"
  default     = "eu-west-2"
}

variable "azs" {
  type    = list(string)
  default = ["eu-west-2a", "eu-west-2b"]
}

variable "vpc_cidr" {
  type        = string
  description = "The VPC CIDR block"
  default     = "172.16.0.0/16"
}

variable "enable_dns_support" {
  type    = bool
  default = true
}

variable "enable_dns_hostnames" {
  type    = bool
  default = true
}

variable "enable_classiclink" {
  type = bool
}

variable "enable_classiclink_dns_support" {
  type = bool
}

variable "preferred_number_of_public_subnets" {
  type        = number
  description = "Number of public subnets"
  default     = 2
}

variable "preferred_number_of_private_subnets" {
  type        = number
  description = "Number of private subnets"
  default     = 4
}

variable "name" {
  type        = string
  description = "The name of the project or environment"
  default     = "production"
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources"
}

variable "ami" {
  type        = string
  description = "AMI ID for the launch template"
}

variable "keypair" {
  type        = string
  description = "Key pair for the EC2 instances"
}

variable "account_no" {
  type        = string
  description = "The AWS account number"
}

variable "master-username" {
  type        = string
  description = "RDS admin username"
}

variable "master-password" {
  type        = string
  description = "RDS master password"
}
```

## Terraform Variables Configuration (`terraform.tfvars`)

This file provides the concrete values for the variables declared in `variables.tf`. It allows Terraform to provision the infrastructure using consistent and environment-specific settings.
```hcl
# AWS Region & VPC Configuration
region                        = "eu-west-2"
vpc_cidr                      = "172.16.0.0/16"
enable_dns_support            = true
enable_dns_hostnames          = true

# Subnet Configuration
preferred_number_of_public_subnets  = 2
preferred_number_of_private_subnets = 4

# ClassicLink Settings
enable_classiclink              = false
enable_classiclink_dns_support  = false

# Project / Environment Name
name = "production"

# EC2 Configuration
ami     = "ami-099400d52583dd8c4"
keypair = "devops"

# AWS Account Information
account_no = "68**********23"

# RDS Database Credentials
master-username = "max"
master-password = "M**St************ord123!"

# Global Resource Tags
tags = {
  Environment     = "production"
  Owner-Email     = "maxi************gmail.com"
  Managed-By      = "Terraform"
  Billing-Account = "68**********23"
}
```

#### Notes:
- **AMI & Keypair:** Replace with your own AMI ID and EC2 key pair if different.
- **AWS Account Number:** Ensure account_no matches your AWS account.
- **Tags:** These are applied globally to all resources for organization, cost tracking, and ownership identification.

This file, together with variables.tf, completes the environment configuration required for Terraform to deploy the infrastructure.

**At this point, the infrastructure is prepared for execution using:**
```bash
terraform init
terraform validate
terraform plan
terraform apply
```





