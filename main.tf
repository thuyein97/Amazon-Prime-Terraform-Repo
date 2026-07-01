terraform {
  required_version = ">= 1.11.0"

  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

variable "project_name" {
  type        = string
  description = "Project name used for tagging and naming."
  default     = "bankapp"
}

variable "environment" {
  type        = string
  description = "Environment name (dev/staging/prod)."
  default     = "prod"
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy EKS into."
  default     = "ap-southeast-1"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name."
  default     = "bankapp-eks"
}

variable "cluster_version" {
  type        = string
  description = "EKS Kubernetes version."
  default     = "1.34"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "node_instance_types" {
  type        = list(string)
  description = "EC2 instance types for EKS managed node group."
  default     = ["t3.small"]
}

variable "node_desired_size" {
  type        = number
  description = "Desired node count."
  default     = 1
}

variable "node_min_size" {
  type        = number
  description = "Minimum node count."
  default     = 1
}

variable "node_max_size" {
  type        = number
  description = "Maximum node count."
  default     = 1
}

variable "gitops_cluster_config_path" {
  type        = string
  description = "Local path for the GitOps bridge file; leave empty in CI."
  default     = ""
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = [for idx, az in local.azs : cidrsubnet(var.vpc_cidr, 4, idx)]
  public_subnets  = [for idx, az in local.azs : cidrsubnet(var.vpc_cidr, 4, idx + 8)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  access_entries = {
    local_admin = {
      principal_arn     = "arn:aws:iam::534856791031:user/terraform_user"
      type              = "STANDARD"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size
      instance_types = var.node_instance_types
      capacity_type  = "SPOT"
    }
  }

  tags = local.tags
}

locals {
  cluster_config_yaml = <<-YAML
  apiVersion: gitops.example.io/v1alpha1
  kind: ClusterConfig
  metadata:
    name: ${module.eks.cluster_name}
  spec:
    clusterName: ${module.eks.cluster_name}
    apiServer: ${module.eks.cluster_endpoint}
    oidcIssuerUrl: ${module.eks.cluster_oidc_issuer_url}
    region: ${var.aws_region}
  YAML
}

resource "local_file" "gitops_cluster_config" {
  count = var.gitops_cluster_config_path != "" ? 1 : 0

  filename        = var.gitops_cluster_config_path
  content         = local.cluster_config_yaml
  file_permission = "0644"
}

output "cluster_name" {
  value       = module.eks.cluster_name
  description = "Provisioned EKS cluster name."
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "Provisioned EKS API endpoint."
}

output "oidc_issuer_url" {
  value       = module.eks.cluster_oidc_issuer_url
  description = "OIDC issuer URL for IAM Roles for Service Accounts."
}

output "cluster_config_yaml" {
  value       = local.cluster_config_yaml
  description = "GitOps bridge file content for clusters/cluster-config.yaml."
}

