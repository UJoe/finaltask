# -----------------------------------------------------------------------------
# versions.tf
#
# Which Terraform version and which providers (plugins) this folder needs.
# The "aws" provider lets Terraform create resources in AWS.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Connect to AWS. Credentials come from your normal AWS CLI login
# (the same ones `aws sts get-caller-identity` shows) - never put keys here.
provider "aws" {
  region = var.region

  # These tags are added to EVERY resource this folder creates. The account is
  # shared, so tags make it easy to see who owns what (and what to clean up).
  default_tags {
    tags = {
      Project   = var.cluster_name
      Owner     = var.owner
      ManagedBy = "terraform"
    }
  }
}
