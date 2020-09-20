provider "google" {
    //credentials = file(C:/Users/VIbhav/Desktop\Google_GCP/credentials/application_default_credentials.json)
    project     = "skilled-index-287206"
    region      = "asia-southeast1"
}

// VPC Creation 

resource "google_compute_network" "vpc_network" {
  name                    = "myvpc-tf"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

// Subnet in Custom VPC

resource "google_compute_subnetwork" "subnet1" {
  network       = google_compute_network.vpc_network.id
  name          = "subnet-1" 
  ip_cidr_range = "192.168.0.0/24" 
  region        = "asia-southeast1"
  
}

// Firewall

resource "google_compute_firewall" "firewall" {
  name          = "firewall-tf"
  network       = google_compute_network.vpc_network.name
  source_ranges = [ "0.0.0.0/0" ]
  allow {
    protocol = "all"
  }
}

resource "google_container_cluster" "gce" {
  name                     = "cluster-tf"
  location                 = "asia-southeast1"
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc_network.name
  subnetwork = google_compute_subnetwork.subnet1.name

}

resource "google_container_node_pool" "node_pool" {
  location   = "asia-southeast1"
  name       = "mynode-tf"
  cluster    = google_container_cluster.gce.name
  node_count = 1

  node_config {
    machine_type = "n1-standard-1"
  }
}
data "google_client_config" "provider" {}

data "google_container_cluster" "my_cluster" {
  name     = "cluster-tf"
  location = "asia-southeast1"
}

provider "kubernetes" {
  load_config_file = false

  host  = "https://${data.google_container_cluster.my_cluster.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate,
  )
}


resource "kubernetes_pod" "wppod" {
  metadata {
    name   = "wordpress-tf"
    labels = {
      app = "wordpress"
    }
  }

  spec {
    container {
      image = "wordpress"
      name  = "mytfwp"
    }
  }
  
}


resource "kubernetes_service" "wplb" {
  metadata {
    name = "wp-loadbalancer-tf"
  }
  spec {
    selector = {
      app    = "wordpress"
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}



output "loadbalancer_IP_Address" {
  value = "${kubernetes_service.wplb.load_balancer_ingress.0.ip}"
}
