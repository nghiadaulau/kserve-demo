# Terraform Setup and Usage Guide

This guide will walk you through setting up and running Terraform to provision the EKS infrastructure for KServe.

## Prerequisites

Before starting, ensure you have completed the prerequisites outlined in the main `prepare.md` file, including:
- Terraform installed
- AWS CLI installed and configured
- Appropriate AWS permissions

## Step 1: Configure AWS Credentials

You need to configure AWS credentials to allow Terraform to interact with your AWS account.

### Option 1: AWS CLI Configuration (Recommended)

Configure AWS credentials using the AWS CLI:

```bash
aws configure
```

You will be prompted to enter:
- **AWS Access Key ID**: Your AWS access key
- **AWS Secret Access Key**: Your AWS secret key
- **Default region name**: `ap-southeast-1` (or your preferred region)
- **Default output format**: `json` (recommended)

### Option 2: Environment Variables

Alternatively, you can set AWS credentials as environment variables:

```bash
export AWS_ACCESS_KEY_ID="your-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
export AWS_DEFAULT_REGION="ap-southeast-1"
```

### Option 3: AWS Credentials File

Create or edit `~/.aws/credentials`:

```ini
[default]
aws_access_key_id = your-access-key-id
aws_secret_access_key = your-secret-access-key
```

And `~/.aws/config`:

```ini
[default]
region = ap-southeast-1
```

### Verify AWS Configuration

Verify that your AWS credentials are configured correctly:

```bash
aws sts get-caller-identity
```

This should return your AWS account ID and user ARN.

## Step 2: Create S3 Bucket for Terraform Backend

Terraform requires an S3 bucket to store the state file. You need to create this bucket before running Terraform.

### Create the S3 Bucket

The backend configuration in `backend.tf` uses the bucket name `eks-demo-terraform-state`. Create this bucket:

```bash
aws s3 mb s3://eks-demo-terraform-state --region ap-southeast-1
```

**Note**: If you want to use a different bucket name, you'll need to update the `bucket` value in `backend.tf`.

### Enable Versioning (Recommended)

Enable versioning on the S3 bucket to protect against accidental deletions:

```bash
aws s3api put-bucket-versioning \
  --bucket eks-demo-terraform-state \
  --versioning-configuration Status=Enabled
```

### Enable Server-Side Encryption (Recommended)

Enable encryption for the state file:

```bash
aws s3api put-bucket-encryption \
  --bucket eks-demo-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

### Block Public Access (Security Best Practice)

Ensure the bucket blocks all public access:

```bash
aws s3api put-public-access-block \
  --bucket eks-demo-terraform-state \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

## Step 3: Configure Terraform Backend

The backend configuration is already set in `backend.tf`. Review and update if necessary:

```hcl
terraform {
  backend "s3" {
    bucket       = "eks-demo-terraform-state"
    key          = "prod/act-workload-prod.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
  }
}
```

**Important**: 
- Ensure the `bucket` name matches the S3 bucket you created
- The `key` is the path where the state file will be stored
- The `region` should match your AWS region
- `use_lockfile = true` enables state locking to prevent concurrent modifications

If you need to change the backend configuration, edit `backend.tf` before running `terraform init`.

## Step 4: Configure Variables

Review and update `terraform.tfvars` with your specific configuration:

```hcl
# Environment and Project
environment = "demo"
project     = "eks-demo"

# VPC Configuration
vpc = {
  cidr                   = "10.0.0.0/16"
  availability_zones     = ["ap-southeast-1a", "ap-southeast-1b"]
  private_subnets        = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets         = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
}
```

Customize these values according to your requirements:
- **environment**: Your environment name (e.g., dev, staging, prod)
- **project**: Your project name
- **vpc.cidr**: VPC CIDR block
- **availability_zones**: AWS availability zones in your region
- **subnets**: Subnet CIDR blocks

## Step 5: Run Terraform

Navigate to the terraform directory:

```bash
cd terraform/
```

### Initialize Terraform

Initialize Terraform and configure the backend:

```bash
terraform init
```

This will:
- Download required providers (AWS, Helm, Kubernetes)
- Configure the S3 backend
- Set up the working directory

**Note**: If you change the backend configuration, you'll need to run `terraform init -reconfigure`.

### Review the Execution Plan

Before applying changes, review what Terraform will create:

```bash
terraform plan
```

This shows:
- Resources that will be created
- Resources that will be modified
- Resources that will be destroyed

Review the plan carefully to ensure it matches your expectations.

### Apply the Configuration

Apply the Terraform configuration to create the infrastructure:

```bash
terraform apply
```

Terraform will prompt you to confirm. Type `yes` to proceed.

**Note**: This process may take 15-30 minutes as it creates:
- VPC and networking components
- EKS cluster
- Node groups
- Security groups
- IAM roles and policies

### Apply with Auto-approve (Optional)

If you're confident in your configuration, you can skip the confirmation prompt:

```bash
terraform apply -auto-approve
```

## Step 6: Configure kubectl

After the Terraform apply completes successfully, configure kubectl to connect to your EKS cluster.

Get the cluster name from Terraform outputs:

```bash
terraform output cluster_name
```

Then configure kubectl:

```bash
aws eks update-kubeconfig \
  --name $(terraform output -raw cluster_name) \
  --region ap-southeast-1
```

Verify the connection:

```bash
kubectl get nodes
```

You should see your EKS nodes listed.

## Common Commands

### View Outputs

View all Terraform outputs:

```bash
terraform output
```

View a specific output:

```bash
terraform output cluster_name
terraform output -raw cluster_name  # Get raw value without quotes
```

### Refresh State

Refresh Terraform state to match the actual infrastructure:

```bash
terraform refresh
```

### Destroy Infrastructure

To destroy all resources created by Terraform:

```bash
terraform destroy
```

**Warning**: This will delete all resources including the EKS cluster, VPC, and all associated resources. Use with caution.

### View State

View the current state:

```bash
terraform show
```

### List Resources

List all resources in the state:

```bash
terraform state list
```

## Troubleshooting

### Backend Configuration Errors

If you encounter backend errors:
- Verify the S3 bucket exists: `aws s3 ls s3://eks-demo-terraform-state`
- Check your AWS credentials: `aws sts get-caller-identity`
- Ensure you have permissions to access the S3 bucket

### State Lock Issues

If Terraform state is locked (another process is running):
- Wait for the other process to complete
- If stuck, you may need to manually unlock (use with caution):
  ```bash
  terraform force-unlock <LOCK_ID>
  ```

### Provider Version Issues

If you encounter provider version conflicts:
- Update `backend.tf` with the required provider versions
- Run `terraform init -upgrade` to update providers

## Next Steps

After successfully deploying the infrastructure:

1. Verify the EKS cluster is running: `kubectl get nodes`
2. Proceed with KServe installation using the provided scripts
3. Refer to the main documentation for KServe deployment steps
