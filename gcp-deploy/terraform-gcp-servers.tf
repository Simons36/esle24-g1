# Elemets of the cloud such as virtual servers,
# networks, firewall rules are created as resources
# syntax is: resource RESOURCE_TYPE RESOURCE_NAME
# https://www.terraform.io/docs/configuration/resources.html

########### Worker Master Servers #############
resource "google_compute_instance" "yb-master" {
    count = var.YB_MASTER_COUNT
    name = "yb-master${count.index+1}"
    machine_type = "n1-standard-2"
    zone = var.GCP_ZONE

    boot_disk {
        initialize_params {
        # Image list can be found at:
        # https://console.cloud.google.com/compute/images
        image = "ubuntu-2004-focal-v20240830"
        type = "pd-ssd"
        }
    }

    network_interface {
        network = "default"
        access_config {
        }
    }

    metadata = {
      ssh-keys = "ubuntu:${file("/home/vagrant/.ssh/id_rsa.pub")}"
    }

    tags = ["yb-master"]
}

########### Tworker Servers #############
resource "google_compute_instance" "yb-tworker" {
    count = var.YB_TSERVER_COUNT
    name = "yb-tworker${count.index+1}"
    machine_type = var.GCP_MACHINE_TYPE
    zone = var.GCP_ZONE

    boot_disk {
        initialize_params {
        # Image list can be found at:
        # https://console.cloud.google.com/compute/images
        image = "ubuntu-2004-focal-v20240830"
        type = "pd-ssd"
        }
    }

    network_interface {
        network = "default"
        access_config {
        }
    }

    metadata = {
      ssh-keys = "ubuntu:${file("/home/vagrant/.ssh/id_rsa.pub")}"
    }

    tags = ["yb-tserver"]
}

