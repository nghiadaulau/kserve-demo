# Prerequisites

Before you can get started with a KServe Quickstart deployment, you will need to ensure you have the following prerequisites installed.

## Tools

Make sure you have the following tools installed:

- **kubectl** - The Kubernetes command-line tool for interacting with your Kubernetes cluster
- **helm** - Package manager for Kubernetes, used for installing KServe and other Kubernetes operators
- **curl** - Command-line tool for transferring data, used by the quickstart script and for testing API endpoints (installed by default on most systems)
- **terraform** - Infrastructure as Code tool for provisioning and managing cloud infrastructure (AWS EKS in this case)
- **grep** - Text search utility, commonly used in scripts for pattern matching (installed by default on most systems)
- **yq** - Command-line YAML processor, used for parsing and manipulating YAML files in scripts

## Verify Installations

Run the following commands to verify that you have the required tools installed:

### Verify kubectl Installation

To verify kubectl installation, run:

```bash
kubectl version --client
```

Expected output should show the client version. Example:
```
Client Version: version.Info{Major:"1", Minor:"28", GitVersion:"v1.28.0", ...}
```

### Verify helm Installation

To verify helm installation, run:

```bash
helm version
```

Expected output should show the helm version. Example:
```
version.BuildInfo{Version:"v3.12.0", ...}
```

### Verify curl Installation

To verify curl installation, run:

```bash
curl --version
```

Expected output should show the curl version. Example:
```
curl 7.88.1 (x86_64-apple-darwin23.0) ...
```

### Verify terraform Installation

To verify terraform installation, run:

```bash
terraform version
```

Expected output should show the terraform version. Example:
```
Terraform v1.6.0
on darwin_amd64
```

### Verify grep Installation

To verify grep installation, run:

```bash
grep --version
```

Expected output should show the grep version. Example:
```
grep (GNU grep) 3.11
```

### Verify yq Installation

To verify yq installation, run:

```bash
yq --version
```

Expected output should show the yq version. Example:
```
yq (https://github.com/mikefarah/yq/) version v4.40.5
```

## AWS GPU Quota (if using AWS)

If you are using AWS for your deployment and plan to use GPU instances, you will need to request GPU quota increases from AWS. This is typically required for instance types such as:

- **p3**, **p4**, **p5** instances (NVIDIA GPUs)
- **g4dn**, **g5** instances (NVIDIA T4, A10G GPUs)
- **inf1**, **inf2** instances (AWS Inferentia chips)

To request a quota increase:

1. Go to the AWS Service Quotas console
2. Navigate to **EC2** service
3. Search for the specific GPU instance type quota you need
4. Request a quota increase with justification for your use case

Alternatively, you can use AWS CLI:

```bash
aws service-quotas request-service-quota-increase \
  --service-code ec2 \
  --quota-code <quota-code> \
  --desired-value <number-of-instances>
```

## Next Steps

Once all prerequisites are verified:

1. Navigate to the `terraform/` directory
2. Review and update `terraform.tfvars` with your specific configuration
3. Initialize Terraform: `terraform init`
4. Plan the deployment: `terraform plan`
5. Apply the infrastructure: `terraform apply`
6. Proceed with KServe installation using the provided scripts

## Installation Links

If you need to install any of the required tools:

- **kubectl**: https://kubernetes.io/docs/tasks/tools/
- **helm**: https://helm.sh/docs/intro/install/
- **terraform**: https://developer.hashicorp.com/terraform/downloads
- **yq**: https://github.com/mikefarah/yq#install
- **AWS CLI**: https://aws.amazon.com/cli/
