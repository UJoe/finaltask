# -----------------------------------------------------------------------------
# versions.tf
#
# Tells Terraform which version of Terraform itself and which "providers"
# (plugins) this project needs. A provider is what lets Terraform talk to a
# specific platform - here, Kubernetes.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
  }
}

# Configure the Kubernetes provider.
# Instead of putting cluster credentials in this file, we reuse the same
# kubeconfig file that `kubectl` uses (~/.kube/config). Whatever cluster
# `kubectl` can reach with the chosen context, Terraform can reach too.
provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kube_context
}
