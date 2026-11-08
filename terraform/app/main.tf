# -----------------------------------------------------------------------------
# main.tf
#
# The actual Kubernetes resources we want to exist:
#   1. a Namespace  - a separate "folder" in the cluster for our app
#   2. a Deployment - runs and keeps alive N copies (pods) of our container
#   3. a Service    - gives those pods one stable name/IP to send traffic to
#
# Terraform compares this desired state with what is really in the cluster
# and creates/changes/deletes things so they match.
# -----------------------------------------------------------------------------

# Labels are key/value tags. The Service uses them to find the Deployment's
# pods, so we define them once here and reuse them everywhere.
locals {
  labels = {
    app = var.app_name
  }
}

# 1. Namespace ----------------------------------------------------------------
resource "kubernetes_namespace_v1" "app" {
  metadata {
    name = var.namespace
  }
}

# 2. Deployment ---------------------------------------------------------------
resource "kubernetes_deployment_v1" "app" {
  metadata {
    name = var.app_name
    # Referencing the namespace resource (instead of typing the name again)
    # also tells Terraform to create the namespace first.
    namespace = kubernetes_namespace_v1.app.metadata[0].name
    labels    = local.labels
  }

  spec {
    # How many pods to run. If one crashes, Kubernetes starts a new one.
    replicas = var.replicas

    # Which pods belong to this Deployment: the ones with these labels.
    selector {
      match_labels = local.labels
    }

    # The template is the "blueprint" for every pod this Deployment creates.
    template {
      metadata {
        labels = local.labels # must match the selector above
      }

      spec {
        container {
          name = var.app_name
          # Full image address, e.g. <ecr-repo>:<commit-sha>
          image = "${var.image_repository}:${var.image_tag}"

          # Our Docker image runs nginx, which listens on port 80.
          port {
            container_port = 80
          }

          # Requests: what the scheduler reserves for the pod.
          # Limits: the most the pod is allowed to use.
          # A static React site served by nginx needs very little.
          resources {
            requests = {
              cpu    = "50m" # 0.05 of a CPU core
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }

          # Readiness probe: Kubernetes only sends traffic to the pod after
          # this HTTP check succeeds.
          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 3
            period_seconds        = 10
          }

          # Liveness probe: if this check keeps failing, Kubernetes
          # restarts the container.
          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 20
          }
        }
      }
    }
  }
}

# 3. Service ------------------------------------------------------------------
# Pods come and go and get new IPs. The Service gives them one stable address
# inside the cluster and load-balances between them.
# Type "ClusterIP" = reachable only from inside the cluster (cheapest, safest).
# Use `kubectl port-forward` to open it from your machine (see README.md).
resource "kubernetes_service_v1" "app" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace_v1.app.metadata[0].name
    labels    = local.labels
  }

  spec {
    type     = "ClusterIP"
    selector = local.labels # send traffic to pods with these labels

    port {
      port        = 80 # port of the Service
      target_port = 80 # port of the container
    }
  }
}
