############################## Operations on Cluster ##############################
data "terraform_remote_state" "infrastructure" {
  backend = "local"
  config = {
    path = "../infrastructure/terraform.tfstate"  # Path to the infrastructure stage's state file
  }
}
provider "kubernetes" {
  host                   = "https://${data.terraform_remote_state.infrastructure.outputs.cluster_endpoint}"
  cluster_ca_certificate = base64decode(data.terraform_remote_state.infrastructure.outputs.kubernetes_cluster_ca_certificate)
  token                  = data.terraform_remote_state.infrastructure.outputs.kubernetes_token
}

provider "helm" {
  kubernetes {
    host                   = "https://${data.terraform_remote_state.infrastructure.outputs.cluster_endpoint}"
    cluster_ca_certificate = base64decode(data.terraform_remote_state.infrastructure.outputs.kubernetes_cluster_ca_certificate)
    token                  = data.terraform_remote_state.infrastructure.outputs.kubernetes_token
  }
}

# Managed Certificate
resource "kubernetes_manifest" "managed_certificate" {
  manifest = {
    apiVersion = "networking.gke.io/v1"
    kind       = "ManagedCertificate"
    metadata = {
      name      = "managed-cert"
      namespace = "default"
    }
    spec = {
      domains = [var.domain]
    }
  }

  depends_on = [
    kubernetes_ingress_v1.hello_world_ingress
  ] 
}

# Ingress
resource "kubernetes_ingress_v1" "hello_world_ingress" {
  metadata {
    name      = "hello-world-ingress"
    namespace = "default"
    annotations = {
      "kubernetes.io/ingress.global-static-ip-name" = "hello-world-static-ip"
      "networking.gke.io/managed-certificates"      = "managed-cert"
      "kubernetes.io/ingress.class"                 = "gce"
    }
  }

  spec {
    rule {
      host = var.domain
      http {
        path {
          path      = "/*"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "hello-world-flask"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    default_backend {
      service {
        name = "hello-world-flask"
        port {
          number = 80
        }
      }
    }
  }
 
}
# ArgoCD
terraform {
  required_providers {    
    argocd = {
      source  = "oboukili/argocd"
      version = "6.1.1"  
    }
  }
}
# Installation ArgoCD using Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  

  namespace = "argocd"

  create_namespace = true

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }  
}
# ArgoCD service IP after installing in cluster
data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = helm_release.argocd.namespace
  }  
}

# ArgoCD administrator password from secret
data "kubernetes_secret" "argocd_admin_secret" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = helm_release.argocd.namespace
  }
}

# Password
locals {
  argocd_password = (data.kubernetes_secret.argocd_admin_secret.data["password"])
}

# Configuration ArgoCD
provider "argocd" {
  server_addr = data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].ip
  username    = "admin"
  password    = local.argocd_password
  insecure    = true  
}

# Setting up argocd for git
resource "argocd_application" "hello_world_flask" {
  metadata {
    name      = "hello-world-flask"
    namespace = "argocd"
  }

  spec {
    project = "default"
    source {
      repo_url = var.git  # address url git repository 
      path     = var.gitpaht # path in git repository 
      target_revision = "HEAD"
    }
    destination {
      server = "https://kubernetes.default.svc"
      namespace = "default"
    }
    sync_policy {
      automated {
        prune = true
        self_heal = true
      }
    }
  }
  depends_on = [ helm_release.argocd ]
}


# Grafana and Prometheus Installation
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"

  namespace = "monitoring"
  create_namespace = true

  values = [
    <<EOF
server:
  global:
    scrape_interval: 15s
serverFiles:
  prometheus.yml:
    scrape_configs:
      - job_name: 'flaskapp'
        static_configs:
          - targets: ['hello-world-flask.default.svc.cluster.local:80']  # Ip metric service
      
EOF
  ]

  depends_on = [kubernetes_ingress_v1.hello_world_ingress ]  
}



resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"

  namespace = "monitoring"
  create_namespace = true

}
