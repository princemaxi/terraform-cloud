# Automate Infrastructure With IaC Using Terraform Cloud

## Project Overview

This project demonstrates how to automate cloud infrastructure provisioning using **Infrastructure as Code (IaC)** with **Terraform** and **Terraform Cloud**. It focuses on migrating an existing Terraform codebase to Terraform Cloud, enabling remote execution, shared state management, GitHub-driven workflows, and operational visibility through notifications.

The project reflects real-world DevOps practices by integrating Terraform Cloud with AWS, GitHub, Packer, and Ansible, while implementing environment separation, governance, and automation.

---

## Why Terraform Cloud?

Terraform is an open-source tool that allows you to define and provision infrastructure using HashiCorp Configuration Language (HCL). Traditionally, Terraform runs locally on a machine managed by the user. While this works for individuals, it becomes inefficient and risky in team-based environments.

Terraform Cloud provides a **managed, centralized, and secure platform** for running Terraform. It eliminates the need to manage local Terraform execution environments and introduces:

* Remote execution on disposable virtual machines
* Centralized and versioned state management
* State locking to prevent concurrent conflicts
* Team collaboration and governance
* VCS-driven automation
* Audit trails and run history
* Notifications and integrations (Email, Slack, Webhooks)

---

## Architecture and Workflow

* **Version Control System (VCS):** GitHub
* **Workflow Type:** Version Control Workflow
* **Cloud Provider:** AWS
* **Execution Mode:** Remote (Terraform Cloud)
* **State Management:** Terraform Cloud Remote Backend
* **Image Management:** Packer
* **Configuration Management:** Ansible

Any change pushed to the configured GitHub branch triggers a Terraform plan in Terraform Cloud. Applies are approved manually to prevent unintended infrastructure changes(very important for production environment).

---

## Repository Structure
```
.
├── AMI/                         # Packer AMI build definitions
│   ├── bastion.pkr.hcl
│   ├── nginx.pkr.hcl
│   ├── tooling.pkr.hcl
│   ├── wordpress.pkr.hcl
│   ├── locals.pkr.hcl
│   ├── plugins.pkr.hcl
│   ├── variables.pkr.hcl
│   ├── *.sh                     # Provisioning shell scripts
│   └── *.pkr.hcl                # Image-specific packer configs
│
├── ansible/                     # Configuration management
│   ├── ansible.cfg
│   ├── inventories/aws/
│   ├── group_vars/
│   ├── playbooks/               # bootstrap, platform, site
│   └── roles/                   # bastion, nginx, tooling, platform, wordpress
│
├── modules/                     # Terraform reusable modules
│   ├── network/                 # VPC, subnets, routing
│   ├── security/                # Security groups, rules
│   ├── iam/                     # IAM roles & policies
│   ├── ALB/                     # External & internal load balancers
│   ├── compute/                 # ASG & Launch Templates
│   ├── EFS/                     # Elastic File System
│   └── RDS/                     # Relational Database Service
│
├── images/                      # Documentation screenshots
├── backend.tf                   # Terraform Cloud backend config
├── backend-resources.tf         # S3 + DynamoDB bootstrap
├── main.tf                      # Root orchestration module
├── variables.tf
├── terraform.tfvars
├── README.md
└── LAB.md
```

## Architectural Diagram
```
┌────────────────────────────────────────────────────────────┐
│                      Terraform Cloud                        │
│        Remote Plan | Apply | State | Locks | Audit           │
└───────────────┬────────────────────────────────────────────┘
                │ GitHub VCS (dev / test / prod branches)
                ▼
┌────────────────────────────────────────────────────────────┐
│                           AWS                               │
│                                                            │
│   ┌────────────────┐                                      │
│   │     Packer     │  Builds Custom AMIs                  │
│   │  (AMI folder)  │───────────────┐                      │
│   └────────────────┘               │                      │
│                                    ▼                      │
│                           ┌──────────────────┐            │
│                           │  EC2 Launch       │            │
│                           │  Templates        │            │
│                           └──────────────────┘            │
│                                    │                      │
│   ┌──────────────┐        ┌──────────────────┐            │
│   │   ALB        │◀──────▶│ Auto Scaling      │            │
│   │ (Ext / Int)  │        │ Groups            │            │
│   └──────────────┘        └──────────────────┘            │
│                                    │                      │
│                                    ▼                      │
│                           ┌──────────────────┐            │
│                           │    Ansible        │            │
│                           │  Configuration    │            │
│                           │  (roles & plays)  │            │
│                           └──────────────────┘            │
│                                    │                      │
│        ┌──────────────┐      ┌──────────────┐            │
│        │     EFS      │      │      RDS     │            │
│        └──────────────┘      └──────────────┘            │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---
## Prerequisites

Ensure the following tools are installed locally:

* Terraform
* Git
* AWS CLI
* Packer
* Ansible

You will also need:

* An AWS account
* A GitHub account
* A Terraform Cloud account

---

## Step-by-Step Implementation

### 1. Create a Terraform Cloud Account

* Sign up at Terraform Cloud
* Verify your email
* Log in to access the Terraform Cloud dashboard

Terraform Cloud offers a free tier that supports all core features required for this project.

---

### 2. Create an Organization

* Select **Start from scratch**
* Provide a unique organization name
* Create the organization

![alt text](/images/1.png)
![alt text](/images/2.png)
![alt text](/images/3.png)

The organization serves as a logical boundary for workspaces, teams, and policies.

---

### 3. Create and Configure a Workspace

1. Create a new GitHub repository (e.g. `terraform-cloud`)
![alt text](/images/4.png)
2. Push your existing Terraform code from previous projects into the repository
![alt text](/images/5.png)
3. In Terraform Cloud:

   * Create a new workspace
   * Select **Version Control Workflow**
   * Connect your GitHub account
   * Select the repository
   * Provide a workspace description(optional)
   * Leave other settings as default
  ![alt text](/images/6.png)
  ![alt text](/images/7.png)
  ![alt text](/images/8.png)
  ![alt text](/images/9.png)
  ![alt text](/images/10.png)

Terraform Cloud will now listen for changes in the repository.

---

### 4. Configure Variables

Terraform Cloud supports:

* **Environment Variables** (for provider credentials)
* **Terraform Variables** (used directly in `.tf` files)

Configure the following environment variables:

* `AWS_ACCESS_KEY_ID`
* `AWS_SECRET_ACCESS_KEY`
![alt text](/images/11.png)
![alt text](/images/12.png)
![alt text](/images/13.png)  

Mark them as **Sensitive** to prevent exposure in logs and UI.

These credentials allow Terraform Cloud to provision AWS resources securely.

---

### 5. Refactor Repository for Packer and Ansible

To support image creation and configuration management:

* Add an `AMI/` directory for AMI builds
  ![alt text](/images/AMI.png)
* Add an `ansible/` directory for configuration scripts
  ![alt text](/images/Ansible.png)

Ensure your Terraform code references the AMIs built by Packer and uses Ansible where required for post-provisioning configuration.

---

### 6. Run Terraform Plan and Apply from Terraform Cloud

* Navigate to the **Runs** tab
  ![alt text](/images/21.png)
* Plan queued plan automatically
* Review the plan output
  ![alt text](/images/22.png)
* If successful, click **Confirm and apply**
  ![alt text](/images/23.png)
* Add a comment and confirm
  ![alt text](/images/24.png)

Terraform Cloud creates a new state version for every successful apply, ensuring full traceability.

---

### 7. Test Automated Runs via GitHub

* Make a change to any `.tf` file
* Commit and push to the connected branch
* Observe that Terraform Cloud automatically triggers a **plan**
![alt text](/images/21.png)

By default:

* Plans run automatically
* Applies require manual approval

This prevents accidental infrastructure changes and unexpected cloud costs.

---

## Practice Task 1: Environment-Based Workflows

### Objectives

1. Create three Git branches:

   * `dev`
   * `test`
   * `prod`
   * Create and configure workspaces for the 3 branches on Terraform cloud 
  ![alt text](/images/26.png)
  ![alt text](/images/43.png)  
  
2. Configure Terraform Cloud to:

   * Automatically trigger runs **only for the dev branch**.
    ![alt text](/images/27.png)
   * Disable auto-runs for test and prod

3. Configure Notifications:

   * Email notifications
   * Slack notifications (optional)
   * Events: plan started, run errored
   ![alt text](/images/33.png)
   ![alt text](/images/34.png)
   ![alt text](/images/35.png)
   ![alt text](/images/36.png)
   ![alt text](/images/37.png) 

4. Destroy infrastructure from Terraform Cloud Web Console

---

### Destroying Infrastructure

* Open the workspace
* Go to **Settings → Destruction and Deletion**
* Queue a destroy plan
* Review and confirm
![alt text](/images/44.png)

This ensures clean teardown without using local Terraform commands.

---

## Public vs Private Module Registry

### Public Module Registry

Terraform provides a public registry containing reusable modules maintained by the community and HashiCorp. These modules accelerate development and promote best practices.

Example use cases:

* VPC modules
* ALB modules
* RDS modules

---

## Troubleshooting Guide

- Backend / State Migration Errors

  * Symptom: Backend configuration changed

  * Fix:

    `terraform init -migrate-state`
    ![alt text](/images/25.png)

- Resource Already Exists Errors

  Occurs when resources were created outside Terraform Cloud state.

  Resolution Options:

  * Import resource into state

  * Remove resource manually

  * Remove stale state reference

- Import Failures

  Ensure:

  * Exact resource name

  * Correct region

  * Resource exists

- Drift Detection

  Terraform Cloud automatically detects drift during plan runs.

## CI/CD Comparison: Terraform Cloud vs GitHub Actions

| Feature        | Terraform Cloud        | GitHub Actions          |
|---------------|------------------------|--------------------------|
| Remote State  | Native (managed)       | Manual setup required    |
| State Locking | Built-in               | Manual (e.g. DynamoDB)   |
| RBAC          | Yes (workspace-level)  | Limited (repo-based)     |
| Audit Logs    | Full run history       | Partial (workflow logs)  |
| Cost Control  | Approval gates         | Custom logic required    |


Terraform Cloud provides an infrastructure-native CI/CD experience, while GitHub Actions requires additional tooling and operational overhead to achieve comparable functionality.

---

### Private Module Registry

For enterprise-scale projects, teams often create internal modules.

Benefits:

* Reusability
* Standardization
* Governance
* Version control

---

## Key Learnings

* Terraform Cloud enables secure, scalable IaC workflows
* Remote state and execution eliminate local risks
* VCS-driven automation improves collaboration
* Notifications enhance visibility and governance
* Environment isolation prevents production risks

---

## Conclusion

This project demonstrates a production-ready approach to Infrastructure as Code using Terraform Cloud. It highlights best practices used by DevOps teams to manage cloud infrastructure reliably, securely, and at scale.

The implementation is suitable for real-world environments, technical interviews, and enterprise DevOps portfolios.
