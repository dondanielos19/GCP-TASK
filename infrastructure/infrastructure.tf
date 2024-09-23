############################## GCP ##############################
provider "google" {
  project = "${var.project_id}"
  region  = var.region
}
provider "google-beta" {
  project     = "${var.project_id}"
  region      = var.region
}

# Enable Google Kubernetes Engine API
resource "google_project_service" "k8s_api" {
  project = var.project_id
  service = "container.googleapis.com"
}

# Enable Compute Engine API
resource "google_project_service" "compute_api" {
  project = var.project_id
  service = "compute.googleapis.com"
}

# Resource for enabling Artifact Registry API
resource "google_project_service" "artifact_registry_api" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"
}

# Wait for APIs to be fully enabled
resource "time_sleep" "wait_for_apis" {
  create_duration = "6m"
  depends_on = [
    google_project_service.k8s_api,
    google_project_service.compute_api,
    google_project_service.artifact_registry_api,
  ]
}

data "google_client_config" "default" {}

# Kubernetes Cluster
resource "google_container_cluster" "primary" {
  name     = "primary-cluster"
  location = var.region
  initial_node_count = 1

  node_config {
    preemptible = true
    machine_type = "e2-medium"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/ndev.clouddns.readwrite"
    ]
  }  
  depends_on = [
    time_sleep.wait_for_apis
  ]
}

# Node pool
resource "google_container_node_pool" "primary_nodes" {
  cluster    = google_container_cluster.primary.name
  location   = google_container_cluster.primary.location
  node_count = 1

  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 20
  }

  depends_on = [
    google_container_cluster.primary,
    time_sleep.wait_for_apis
  ]  
}

# Obtaining credentials using gcloud
resource "null_resource" "get_kube_credentials" {
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${google_container_cluster.primary.location} --project ${var.project_id}"
  }

  depends_on = [
    google_container_cluster.primary,
    google_container_node_pool.primary_nodes
  ]
}

# Static IP
resource "google_compute_global_address" "static_ip" {
  name = "hello-world-static-ip"
}

# Create DNS Zone
resource "google_dns_managed_zone" "zone" {
  name        = "zone-name"
  dns_name    = "${var.domain}."
  description = "DNS ZONE for your domain"
}

# Record A
resource "google_dns_record_set" "a_record" {
  name         = "${var.domain}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.zone.name

  rrdatas = [google_compute_global_address.static_ip.address]   
}

# Resource for enabling Artifact Registry API
resource "google_artifact_registry_repository" "docker_repo" {
  provider     = google
  project      = var.project_id
  location     = var.region
  repository_id = "repo"
  format       = "DOCKER"
  description  = "My Docker repository"
}

# Build and push Docker image using null_resource and local-exec
resource "null_resource" "docker_build_and_push" {
  provisioner "local-exec" {
    command = <<EOT
      docker build -f /home/dondnaielos/chwilaprawdy/Dockerfile -t ${var.region}-docker.pkg.dev/${var.project_id}/repo/hello-world-flask:v1 /home/dondnaielos/chwilaprawdy
      docker push ${var.region}-docker.pkg.dev/${var.project_id}/repo/hello-world-flask:v1
    EOT
  }

  depends_on = [
    google_project_service.artifact_registry_api,
    google_artifact_registry_repository.docker_repo
  ]
}

# Outputs for the cluster
output "cluster_endpoint" {
  value = google_container_cluster.primary.endpoint
}

output "kubernetes_cluster_ca_certificate" {
  value = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
}

output "kubernetes_token" {
  value = data.google_client_config.default.access_token
  sensitive = true
}
