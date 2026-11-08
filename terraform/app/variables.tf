# -----------------------------------------------------------------------------
# variables.tf
#
# Input variables are the "settings" of this Terraform project. Instead of
# hard-coding values in main.tf, we declare them here so they can be changed
# without editing the code (e.g. in terraform.tfvars or with -var on the
# command line).
# -----------------------------------------------------------------------------

variable "kubeconfig_path" {
  description = "Path to the kubeconfig file that kubectl uses."
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Which kubeconfig context (= which cluster) to deploy to. Run `kubectl config get-contexts` to see them."
  type        = string
  # No default on purpose: you must decide consciously which cluster to use.
}

variable "namespace" {
  description = "Kubernetes namespace to deploy into. A namespace is like a folder that groups resources."
  type        = string
  default     = "finaltask"
}

variable "app_name" {
  description = "Name used for the Deployment, the Service and their labels."
  type        = string
  default     = "finaltask"
}

variable "image_repository" {
  description = "The ECR repository our GitHub Actions workflow pushes the image to."
  type        = string
  default     = "362099375729.dkr.ecr.eu-central-1.amazonaws.com/ugergo/finaltask"
}

variable "image_tag" {
  description = "Which image version to run. Our pipeline tags every image with the git commit SHA."
  type        = string
  # No default: always deploy a specific, known version (never "latest").
}

variable "replicas" {
  description = "How many copies (pods) of the app should run at the same time."
  type        = number
  default     = 2
}
