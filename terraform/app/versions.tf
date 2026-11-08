# -----------------------------------------------------------------------------
# versions.tf
#
# Tells Terraform which version of Terraform itself and which "providers"
# (plugins) this project needs. A provider is what lets Terraform talk to a
# specific platform - here AWS (to find the cluster) and Kubernetes.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.10.0" # 1.10+ is needed for S3 state locking (use_lockfile)

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
  }

  # Where Terraform keeps its "state" (its record of what it created).
  # It must be in S3, not on your laptop: the GitHub Actions runner starts
  # empty every time, so it needs a shared place to read the state from.
  # use_lockfile stops two runs (yours and the pipeline's) from changing
  # things at the same time.
  # Note: values here cannot use variables - they must be written out.
  backend "s3" {
    bucket       = "ugergo-finaltask-tfstate"
    key          = "app/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region
}

# Look up the EKS cluster created by the terraform/eks folder.
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

# Configure the Kubernetes provider.
# There is no ~/.kube/config on a GitHub runner, so instead of reading one we
# give the provider the cluster's address and certificate, and let it get a
# short-lived login token from AWS by running `aws eks get-token`.
# This works the same on your laptop and in the pipeline.
provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.region]
  }
}
