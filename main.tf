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

variable "yc_token" {}
provider "yandex" {
  token  = var.yc_token
  cloud_id = "b1gtk8bi8ed21l2l3aui"
  folder_id = "b1gv4ctc2qlvoraa4gig"
  zone = "ru-central1-a"
}

variable "datadog_api_key" { }
variable "datadog_app_key" { }
provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  api_url = "https://api.datadoghq.eu/"
}


resource "yandex_compute_instance" "vm-1" {

  name                      = "dev3"
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
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    nat       = true
  }

  metadata = {
    ssh-keys = "danny:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCYDTxx/Luo3BCKBCKsD93Rez1T9etSqZ2/LkqX3geqJX/XiXNrndyPE6qTT91YSjIGZU4mgksspSFuHvscksI3LVwwbtJKkeD9FEX9cVe3w16jvry/ln/aF62p2apvim3GIVhm5vktInYlcxT8mxEbhyl1nydT8eBrtP/85/oEDqEx07uPpi1/xnIv/yUr95y4Np7vseRiUSgojTdKTID0ojmg4Qkv0GFE1V3o9nXGLIZGRAVgILqg4QyiVtkHMW5QyaFC8VVMy47fDd5higQTbv/a3njcuvoxRj7yRa6oxAkAMs/Ne+tJ2ANf/znxlaoP8KNVR0EMTDBsSWkzUguWN7d+ZylWCoL9OwoOwcbbSNT13ypM+DqF8k1/F5W44ifrLqk+jNKMjbuyc6sSRcR/8Wus6ZTM7nuniUhNpowtmU4ym35Bv/0kW8G5IATUoMf2hseHYpJCPK07q3SrNSoAEc2y7h6cXhTvkJU5Fk2iY+jEmbP2BDDa4cUnbshl1Gc= danny@danny-notebook-ubuntu"
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  v4_cidr_blocks = ["192.168.10.0/24"]
  network_id     = "${yandex_vpc_network.network-1.id}"
}