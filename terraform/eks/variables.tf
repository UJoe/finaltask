# -----------------------------------------------------------------------------
# variables.tf
#
# The settings of this folder. Change them in terraform.tfvars instead of
# editing main.tf.
# -----------------------------------------------------------------------------

variable "region" {
  description = "AWS region to create everything in."
  type        = string
  default     = "eu-central-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster (also used to name the VPC)."
  type        = string
  default     = "ugergo-finaltask"
}

variable "owner" {
  description = "Who owns these resources. Added as a tag, because the AWS account is shared."
  type        = string
  default     = "ugergo"
}

variable "kubernetes_version" {
  description = "Kubernetes version of the cluster."
  type        = string
  default     = "1.37"
}

variable "vpc_cidr" {
  description = "IP address range of the new VPC (the private network the cluster lives in)."
  type        = string
  default     = "10.0.0.0/16"
}

variable "node_instance_type" {
  description = "EC2 instance type of the worker nodes (the machines that run our pods)."
  type        = string
  default     = "t3.small"
}

variable "node_count" {
  description = "How many worker nodes to run."
  type        = number
  default     = 2
}

variable "github_actions_role_arn" {
  description = "IAM role that the GitHub Actions pipeline assumes. It gets access to the cluster so it can deploy the app."
  type        = string
  default     = "arn:aws:iam::362099375729:role/finaltaskberheles"
}
