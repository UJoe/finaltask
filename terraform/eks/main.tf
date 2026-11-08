# -----------------------------------------------------------------------------
# main.tf
#
# Creates the infrastructure for our app:
#   1. a VPC     - our own private network in AWS
#   2. an EKS cluster with a group of worker nodes inside that VPC
#
# Instead of writing ~50 low-level resources ourselves, we use two official,
# widely used community modules. A module is a reusable package of Terraform
# code: we only pass in a few settings and it builds the rest.
# -----------------------------------------------------------------------------

# Ask AWS which availability zones (separate data centers) the region has.
# We spread the cluster over 2 of them, so one data center failing does not
# take down the whole app.
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

# 1. VPC ----------------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = var.cluster_name
  cidr = var.vpc_cidr
  azs  = local.azs

  # Each AZ gets one private and one public subnet (a slice of the VPC's IPs).
  # cidrsubnet() cuts the /16 VPC range into smaller /20 blocks for us.
  #   - Private subnets: the worker nodes live here, not reachable from the internet.
  #   - Public subnets:  for internet-facing load balancers and the NAT gateway.
  private_subnets = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnets  = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 4, i + 4)]

  # A NAT gateway lets the private nodes reach the internet (e.g. to pull
  # images) without being reachable from it. One shared NAT gateway is
  # cheaper than one per AZ - fine for a learning project.
  enable_nat_gateway = true
  single_nat_gateway = true

  # These tags tell Kubernetes which subnets it may use when it creates
  # load balancers: public ones for internet-facing, private ones for internal.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

# 2. EKS cluster --------------------------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  # Let us reach the Kubernetes API (kubectl, Terraform) from our own machine.
  endpoint_public_access = true

  # Give the person who runs `terraform apply` admin rights in the cluster.
  # Without this, even the creator could not use kubectl on it.
  enable_cluster_creator_admin_permissions = true

  # Also let the GitHub Actions role (used by the terraform-app.yml pipeline)
  # into the cluster, so the pipeline can deploy the app.
  # An "access entry" maps an AWS IAM role to permissions inside Kubernetes.
  access_entries = {
    github_actions = {
      principal_arn = var.github_actions_role_arn
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster" # the pipeline creates the namespace, so it needs cluster-wide rights
          }
        }
      }
    }
  }

  # Put the cluster into the VPC created above, using the private subnets.
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Add-ons are core cluster components that AWS installs and updates for us.
  addons = {
    coredns    = {}         # DNS inside the cluster (lets pods find Services by name)
    kube-proxy = {}         # routes Service traffic to the right pods
    vpc-cni = {             # gives every pod an IP address from the VPC
      before_compute = true # must exist before the nodes start
    }
    eks-pod-identity-agent = {
      before_compute = true # lets pods use IAM roles (needed by many add-ons)
    }
  }

  # A managed node group: EC2 machines that AWS creates and keeps healthy for us.
  # The module also gives them permission to pull images from ECR.
  eks_managed_node_groups = {
    default = {
      instance_types = [var.node_instance_type]

      min_size     = var.node_count
      max_size     = var.node_count
      desired_size = var.node_count
    }
  }
}
