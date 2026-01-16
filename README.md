# KServe Demo - Complete Setup Guide

This repository contains a complete guide and infrastructure setup for deploying KServe on Amazon EKS with GPU support.

## Overview

This demo provides step-by-step instructions to:
1. Set up prerequisites and required tools
2. Provision EKS infrastructure using Terraform
3. Install NVIDIA GPU Device Plugin
4. Install KServe (Standard Mode) with LLMInferenceService
5. Deploy and configure KServe for model serving

## Quick Start

Follow these guides in order:

### 1. Prerequisites Setup

Before you begin, ensure you have all required tools installed and configured.

📖 **[Prerequisites Guide →](prepare.md)**

This guide covers:
- Required tools (kubectl, helm, curl, terraform, grep, yq)
- Verification commands for each tool
- AWS GPU quota requirements (if using AWS)

### 2. Terraform Infrastructure Deployment

Deploy your EKS cluster and infrastructure using Terraform.

📖 **[Terraform Setup Guide →](terraform.md)**

This guide covers:
- AWS credentials configuration
- S3 backend setup for Terraform state
- Terraform initialization and deployment
- EKS cluster provisioning
- kubectl configuration

### 3. GPU Device Plugin Installation

Install the NVIDIA Kubernetes Device Plugin to enable GPU support in your cluster.

📖 **[GPU Device Plugin Installation Guide →](install-gpu-device-plugin.md)**

This guide covers:
- Prerequisites verification
- Automated and manual installation methods
- Verification and testing
- Troubleshooting common issues

### 4. KServe Installation

Install KServe (Standard Mode) and LLMInferenceService on your EKS cluster.

📖 **[KServe Installation Guide →](install-kserve.md)**

This guide covers:
- Prerequisites verification
- Running the installation script
- Verifying all components
- Creating your first InferenceService
- Troubleshooting installation issues

## Architecture

This setup creates:

- **EKS Cluster** with:
  - General purpose node group (t3.medium instances)
  - GPU-enabled node group (g4dn.xlarge instances with NVIDIA GPUs)
  - VPC with public and private subnets
  - Security groups and networking configuration

- **NVIDIA Device Plugin** for GPU resource management

- **KServe-ready environment** for model serving

## Directory Structure

```
.
├── README.md                          # This file
├── prepare.md                         # Prerequisites setup guide
├── terraform.md                       # Terraform deployment guide
├── install-gpu-device-plugin.md      # GPU plugin installation guide
├── install-kserve.md                  # KServe installation guide
├── terraform/                         # Terraform configuration files
│   ├── backend.tf                     # S3 backend configuration
│   ├── provider.tf                   # AWS provider configuration
│   ├── vpc.tf                         # VPC and networking
│   ├── eks.tf                         # EKS cluster and node groups
│   ├── security_group.tf             # Security group rules
│   ├── addons.tf                      # EKS addons
│   ├── outputs.tf                     # Terraform outputs
│   ├── variables.tf                   # Variable definitions
│   └── terraform.tfvars              # Variable values
└── docs/                              # Additional documentation
    └── install-kubernetes-device-plugin-for-gpus.sh  # Installation script
```

## Prerequisites Summary

Before starting, ensure you have:

- ✅ **kubectl** - Kubernetes command-line tool
- ✅ **helm** - Kubernetes package manager
- ✅ **terraform** - Infrastructure as Code tool
- ✅ **curl** - Command-line data transfer tool
- ✅ **grep** - Text search utility
- ✅ **yq** - YAML processor
- ✅ **AWS CLI** - Configured with appropriate credentials
- ✅ **AWS Account** - With permissions to create EKS, VPC, and related resources
- ✅ **GPU Quota** - Requested from AWS if using GPU instances

## Getting Started

1. **Read the Prerequisites Guide**
   ```bash
   # Review prepare.md and verify all tools are installed
   ```

2. **Deploy Infrastructure**
   ```bash
   # Follow terraform.md to deploy EKS cluster
   cd terraform/
   terraform init
   terraform plan
   terraform apply
   ```

3. **Install GPU Device Plugin**
   ```bash
   # Follow install-gpu-device-plugin.md
   cd docs/
   ./install-kubernetes-device-plugin-for-gpus.sh
   ```

4. **Install KServe**
   ```bash
   # Follow install-kserve.md
   cd kserve/
   ./hack/setup/quick-install/kserve-standard-mode-full-install-with-manifests.sh
   ```

5. **Verify Installation**
   ```bash
   # Check GPU resources are available
   kubectl get nodes -o=custom-columns=NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu
   
   # Check KServe pods
   kubectl get pods -n kserve
   ```

## Next Steps

After completing the setup:

1. ✅ KServe is installed - See [install-kserve.md](install-kserve.md) for verification
2. Deploy your first model inference service
3. Configure autoscaling and resource management
4. Set up monitoring and logging

## Troubleshooting

Each guide includes a troubleshooting section. Common issues:

- **Terraform backend errors**: Check S3 bucket exists and credentials are configured
- **GPU not showing**: Verify device plugin DaemonSet is running
- **Node group not joining**: Check security groups and IAM roles

## References

- [KServe Documentation](https://kserve.github.io/website/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [NVIDIA Device Plugin](https://github.com/NVIDIA/k8s-device-plugin)
- [Terraform AWS EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/)

## Support

For issues specific to:
- **Prerequisites**: See [prepare.md](prepare.md)
- **Terraform deployment**: See [terraform.md](terraform.md)
- **GPU plugin**: See [install-gpu-device-plugin.md](install-gpu-device-plugin.md)
- **KServe installation**: See [install-kserve.md](install-kserve.md)

## License

This demo setup follows the same license as the KServe project.
