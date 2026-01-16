module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name                   = "${var.project}-cluster"
  cluster_version                = "1.32"
  cluster_endpoint_public_access = true

  vpc_id                                 = module.vpc.vpc_id
  subnet_ids                             = module.vpc.private_subnets
  cloudwatch_log_group_retention_in_days = 0
  create_cloudwatch_log_group            = false
  cluster_enabled_log_types              = []
  create_cluster_security_group          = false
  create_node_security_group             = false

  eks_managed_node_groups = {
    general = {
      use_custom_launch_template = false
      ami_type                   = "AL2023_x86_64_STANDARD"
      desired_size               = 2
      max_size                   = 2
      min_size                   = 2

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 100
    }
    gpu = {
      use_custom_launch_template = false
      ami_type                   = "AL2023_x86_64_NVIDIA"
      desired_size               = 2
      max_size                   = 2
      min_size                   = 2

      instance_types = ["g4dn.xlarge"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 200
    }
  }

  manage_aws_auth_configmap = false
  aws_auth_roles            = []

  tags = {
    Environment              = var.environment
    Project                  = var.project
    ManagedBy                = "terraform"
    "karpenter.sh/discovery" = "${var.project}-cluster"
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}
