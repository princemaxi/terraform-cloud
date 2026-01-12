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

Any change pushed to the configured GitHub branch triggers a Terraform plan in Terraform Cloud. Applies are approved manually to prevent unintended infrastructure changes.

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

The organization serves as a logical boundary for workspaces, teams, and policies.

---

### 3. Create and Configure a Workspace

1. Create a new GitHub repository (e.g. `terraform-cloud`)
2. Push your existing Terraform code from previous projects into the repository
3. In Terraform Cloud:

   * Create a new workspace
   * Select **Version Control Workflow**
   * Connect your GitHub account
   * Select the repository
   * Provide a workspace description
   * Leave other settings as default

Terraform Cloud will now listen for changes in the repository.

---

### 4. Configure Variables

Terraform Cloud supports:

* **Environment Variables** (for provider credentials)
* **Terraform Variables** (used directly in `.tf` files)

Configure the following environment variables:

* `AWS_ACCESS_KEY_ID`
* `AWS_SECRET_ACCESS_KEY`

Mark them as **Sensitive** to prevent exposure in logs and UI.

These credentials allow Terraform Cloud to provision AWS resources securely.

---

### 5. Refactor Repository for Packer and Ansible

To support image creation and configuration management:

* Add a `packer/` directory for AMI builds
* Add an `ansible/` directory for configuration scripts

Ensure your Terraform code references the AMIs built by Packer and uses Ansible where required for post-provisioning configuration.

---

### 6. Run Terraform Plan and Apply from Terraform Cloud

* Navigate to the **Runs** tab
* Click **Queue plan manually**
* Review the plan output
* If successful, click **Confirm and apply**
* Add a comment and confirm

Terraform Cloud creates a new state version for every successful apply, ensuring full traceability.

---

### 7. Test Automated Runs via GitHub

* Make a change to any `.tf` file
* Commit and push to the connected branch
* Observe that Terraform Cloud automatically triggers a **plan**

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

2. Configure Terraform Cloud to:

   * Automatically trigger runs **only for the dev branch**
   * Disable auto-runs for test and prod

3. Configure Notifications:

   * Email notifications
   * Slack notifications
   * Events: plan started, run errored

4. Destroy infrastructure from Terraform Cloud Web Console

---

### Destroying Infrastructure

* Open the workspace
* Go to **Settings → Destruction and Deletion**
* Queue a destroy plan
* Review and confirm

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

### Private Module Registry

For enterprise-scale projects, teams often create internal modules.

Benefits:

* Reusability
* Standardization
* Governance
* Version control

---

## Practice Task 2: Working with Private Modules

1. Create a simple Terraform module repository
2. Push the module to GitHub
3. Import it into Terraform Cloud Private Registry
4. Reference the module in a Terraform configuration
5. Create a workspace
6. Deploy infrastructure
7. Destroy deployment

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
