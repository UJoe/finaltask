# -----------------------------------------------------------------------------
# outputs.tf
#
# Outputs are values Terraform prints after `terraform apply`. They are handy
# for checking the result or for copying into the next command.
# -----------------------------------------------------------------------------

output "namespace" {
  description = "Namespace the app was deployed to."
  value       = kubernetes_namespace_v1.app.metadata[0].name
}

output "deployed_image" {
  description = "The exact image the pods are running."
  value       = "${var.image_repository}:${var.image_tag}"
}

output "port_forward_command" {
  description = "Run this, then open http://localhost:8080 in your browser."
  value       = "kubectl -n ${kubernetes_namespace_v1.app.metadata[0].name} port-forward service/${kubernetes_service_v1.app.metadata[0].name} 8080:80"
}
