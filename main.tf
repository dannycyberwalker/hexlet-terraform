terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "0.97.0"
    }

    datadog = {
      source = "DataDog/datadog"
      version = "3.29.0"
    }
  }
}



variable "yc_token" { sensitive = true }
provider "yandex" {
  token  = var.yc_token
  cloud_id = "b1gtk8bi8ed21l2l3aui"
  folder_id = "b1gv4ctc2qlvoraa4gig"
  zone = "ru-central1-a"
}

variable "datadog_api_key" { sensitive = true }
variable "datadog_app_key" { sensitive = true }
provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  api_url = "https://api.datadoghq.eu/"
}


resource "yandex_compute_instance" "dev1" {

  name                      = "dev1"
  allow_stopping_for_update = true
  platform_id               = "standard-v3"
  zone                      = "ru-central1-a"

  resources {
    cores  = "2"
    memory = "2"
  }

  boot_disk {
    initialize_params {
      image_id = "fd8fco5lpqbhanbfg2du" // ubuntu 22.04
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.main_subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_compute_instance" "dev2" {

  name                      = "dev2"
  allow_stopping_for_update = true
  platform_id               = "standard-v3"
  zone                      = "ru-central1-a"

  resources {
    cores  = "2"
    memory = "2"
  }

  boot_disk {
    initialize_params {
      image_id = "fd8fco5lpqbhanbfg2du" // ubuntu 22.04
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.main_subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_alb_target_group" "main-target-group" {
  name           = "maintargetgroup"

  target {
    subnet_id    = yandex_vpc_subnet.main_subnet.id
    ip_address   = yandex_compute_instance.dev1.network_interface.0.ip_address
  }

  target {
    subnet_id    = yandex_vpc_subnet.main_subnet.id
    ip_address   = yandex_compute_instance.dev2.network_interface.0.ip_address
  }
}

resource "yandex_alb_backend_group" "main-backend-group" {
  name                     = "mainbackendgroup"
  session_affinity {
    connection {
      source_ip = false
    }
  }

  http_backend {
    name                   = "mainbackend"
    weight                 = 1
    port                   = 3000
    target_group_ids       = [ yandex_alb_target_group.main-target-group.id ]
    load_balancing_config {
      panic_threshold      = 90
    }    
    healthcheck {
      timeout              = "10s"
      interval             = "2s"
      healthy_threshold    = 10
      unhealthy_threshold  = 15 
      http_healthcheck {
        path               = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "main-router" {
  name          = "mainrouter"
  labels        = {
    tf-label    = "tf-label-value"
    empty-label = ""
  }
}

resource "yandex_alb_virtual_host" "main-virtual-host" {
  name                    = "mainvirtualhost"
  http_router_id          = yandex_alb_http_router.main-router.id
  route {
    name                  = "mainroute"
    http_route {
      http_route_action {
        backend_group_id  = yandex_alb_backend_group.main-backend-group.id
        timeout           = "60s"
      }
    }
  }
}   

resource "yandex_alb_load_balancer" "l7-balancer" {
  name        = "l7balancer"
  network_id  = yandex_vpc_network.main_network.id

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.main_subnet.id
    }
  }

  listener {
    name = "mainlistener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.main-router.id
      }
    }
  }

  log_options {
    discard_rule {
      http_code_intervals = ["HTTP_2XX", "HTTP_5XX"]
      discard_percent = 75
    }
  }
}


resource "yandex_vpc_network" "main_network" {
  name = "main_network"
}

resource "yandex_vpc_subnet" "main_subnet" {
  name           = "main_subnet"
  zone           = "ru-central1-a"
  v4_cidr_blocks = ["192.168.10.0/24"]
  network_id     = "${yandex_vpc_network.main_network.id}"
}