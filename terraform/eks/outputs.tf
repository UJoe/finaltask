# -----------------------------------------------------------------------------
# outputs.tf
#
# Values printed after `terraform apply`.
# -----------------------------------------------------------------------------

output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "kubeconfig_command" {
  description = "Run this to let kubectl (and the app/ folder) talk to the new cluster."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "kube_context" {
  description = "The kubeconfig context name to use as kube_context in app/terraform.tfvars."
  value       = module.eks.cluster_arn
}
