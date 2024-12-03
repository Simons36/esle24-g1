# Elemets of the cloud such as virtual servers,
# networks, firewall rules are created as resources
# syntax is: resource RESOURCE_TYPE RESOURCE_NAME
# https://www.terraform.io/docs/configuration/resources.html

resource "google_compute_firewall" "frontend_rules" {
  name    = "frontend"
  network = "default"

  allow {
    protocol = "tcp"
    ports = ["80", "443", "7000", "7100", "5433", "9042", "9100", "8800"]
  }

  source_ranges = ["0.0.0.0/0"]
}
