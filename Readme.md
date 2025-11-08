# B9IS121: Automated Container Deployment on AWS

This repository contains the practical work for the **B9IS121: Network Systems and Administration** module. The project's goal is to demonstrate a fully automated pipeline for deploying a containerized web application to the AWS cloud.

This entire process is automated using a CI/CD pipeline. When code is pushed to the `main` branch, the infrastructure is built, the server is configured, and the application is deployed without any manual intervention.

## Technology Stack

This project integrates the following key technologies as required by the assignment:

  * **Cloud Provider:** AWS (Amazon Web Services)
  * **Infrastructure as Code (IaC):** Terraform (Part 1)
  * **Configuration Management:** Ansible (Part 2)
  * **Containerization:** Docker (Part 3)
  * **CI/CD Pipeline:** GitHub Actions (Part 4)
  * **Application:** Nginx (serving a custom HTML page)

## 🏛️ Architecture & Workflow

The architecture is designed around an automated CI/CD workflow triggered by a `git push`.

**\[Note: You must create an architecture diagram and add it here for your report. The diagram should show the flow below.]**

1.  **Trigger:** A developer pushes a code change to the `main` branch on GitHub.
2.  **CI/CD Pipeline (Part 4):** GitHub Actions detects the push and starts the `deploy` workflow.
3.  **Provision Infrastructure (Part 1):** The workflow uses Terraform to provision the required infrastructure on AWS:
      * An EC2 (t3.micro) instance.
      * A Security Group that allows SSH (port 22) and HTTP (port 80).
      * Terraform then outputs the new server's public IP address.
4.  **Configure Server (Part 2):** The workflow uses Ansible to configure the new EC2 instance. It:
      * Waits for the server to be ready.
      * Installs Docker.
      * Installs required Python libraries (`docker`, `pip`).
      * Starts the Docker service.
5.  **Deploy Application (Part 3):** The Ansible playbook continues by:
      * Copying the `html/` directory (webpage and assets) to the server.
      * Pulling the `nginx:latest` image.
      * Starting the Nginx container, mounting the `html` directory as a volume, and mapping port 80.
6.  **Live:** The deployment is complete, and the new website is available at the server's public IP.

## Project Structure

This repository is organized as follows:

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml      # (Part 4) GitHub Actions workflow file
│
├── html/
│   ├── assets/             # Contains all image assets (logos)
│   │   ├── ansible.png
│   │   ├── docker.png
│   │   ├── github.png
│   │   └── terraform.png
│   │
│   └── index.html          # (Part 3) The sample webpage
│
├── main.tf                 # (Part 1) Terraform script for AWS infrastructure
├── playbook.yml            # (Part 2 & 3) Ansible playbook for server config
├── inventory.ini           # Ansible inventory file (for manual runs)
└── README.md               # This documentation file
```

-----

## How to Run

You can deploy this project in two ways: automatically (via CI/CD) or manually.

### 1\. Automated Deployment (CI/CD)

This is the primary method for deployment and meets the **Part 4** requirement.

1.  **Prerequisite:** Configure the required GitHub Repository Secrets (see section below).
2.  **Action:** Make a change to any file (e.g., edit `html/index.html`).
3.  **Trigger:** `git add .`, `git commit -m "My change"`, and `git push origin main`.
4.  **Monitor:** Go to the "Actions" tab in your GitHub repository to watch the pipeline build, provision, and deploy your application.

#### Required GitHub Secrets

You must add the following to your GitHub repository's **Settings \> Secrets and variables \> Actions** for the pipeline to work:

  * `AWS_ACCESS_KEY_ID`: Your AWS IAM user access key.
  * `AWS_SECRET_ACCESS_KEY`: Your AWS IAM user secret key.
  * `EC2_SSH_KEY`: The **private key** (e.g., the content of your `.pem` file) that pairs with the key on AWS.
  * `AWS_REGION`: The region to deploy to (e.g., `us-east-1`).

-----

### 2\. Manual Deployment

You can also run the entire process manually from your local machine.

#### Prerequisites

  * [Terraform](https://www.google.com/search?q=https://learn.hash.co/tutorials/terraform/install-cli) installed.
  * [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) installed.
  * [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) installed and configured (`aws configure`).
  * Your AWS SSH private key (e.g., `Network.pem`) must be in the root folder, and its permissions must be set:
    ```bash
    chmod 400 Network.pem
    ```

#### Step 1: Run Terraform (Part 1)

This step will create the EC2 server and security group.

```bash
# Initialize Terraform
terraform init

# Build the infrastructure
terraform apply -auto-approve
```

When the command finishes, Terraform will print the server's public IP. **Copy this IP address.**

```bash
Outputs:

application_public_ip = "54.123.45.67"
```

#### Step 2: Update Inventory

Open the `inventory.ini` file. Replace the text `YOUR_SERVER_IP_HERE` with the IP address you just copied.

#### Step 3: Run Ansible (Part 2 & 3)

This command tells Ansible to use your `inventory.ini` file to configure the server using the steps in `playbook.yml`.

*Note: The `--ssh-common-args` flag is needed to bypass the "Are you sure you want to connect?" (SSH host key) prompt that would normally stop an automated script.*

```bash
ansible-playbook -i inventory.ini playbook.yml --ssh-common-args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
```

#### Step 4: Verify

Your website is now live\! You can visit your server's IP in a web browser:
**`http://<YOUR_SERVER_IP_HERE>`**