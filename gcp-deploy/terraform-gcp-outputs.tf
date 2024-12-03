# Output for Master IPs (Public and Private)
output "yb_master_IPs" {
  value = formatlist("%s = %s", google_compute_instance.yb-master[*].name, google_compute_instance.yb-master[*].network_interface.0.access_config.0.nat_ip)
}

output "yb_master_private_IPs" {
  value = formatlist("%s = %s", google_compute_instance.yb-master[*].name, google_compute_instance.yb-master[*].network_interface.0.network_ip)
}

output "yb_master_ssh" {
  value = formatlist("%s = %s", google_compute_instance.yb-master[*].name, google_compute_instance.yb-master[*].self_link)
}

# Output for Tworker IPs (Public and Private)
output "yb_tworker_IPs" {
  value = formatlist("%s = %s", google_compute_instance.yb-tworker[*].name, google_compute_instance.yb-tworker[*].network_interface.0.access_config.0.nat_ip)
}

output "yb_tworker_private_IPs" {
  value = formatlist("%s = %s", google_compute_instance.yb-tworker[*].name, google_compute_instance.yb-tworker[*].network_interface.0.network_ip)
}

output "tworker_ssh" {
  value = formatlist("%s = %s", google_compute_instance.yb-tworker[*].name, google_compute_instance.yb-tworker[*].self_link)
}

# Updated Locals
locals {
  # Masters inventory
  yb_masters = [
    for i in range(length(google_compute_instance.yb-master)) : {
      id         = google_compute_instance.yb-master[i].name
      public_ip  = google_compute_instance.yb-master[i].network_interface.0.access_config.0.nat_ip
      private_ip = google_compute_instance.yb-master[i].network_interface.0.network_ip
    }
  ]

  # Tworkers inventory
  yb_tworkers = [
    for i in range(length(google_compute_instance.yb-tworker)) : {
      id         = google_compute_instance.yb-tworker[i].name
      public_ip  = google_compute_instance.yb-tworker[i].network_interface.0.access_config.0.nat_ip
      private_ip = google_compute_instance.yb-tworker[i].network_interface.0.network_ip
    }
  ]

  # Generate inventory content for masters and tworkers
  inventory_content = templatefile("${path.module}/templates/inventory.ini.j2", {
    yb_masters  = local.yb_masters
    yb_tworkers = local.yb_tworkers
  })

  vars_content = templatefile("${path.module}/templates/vars.yml.j2", {
    yb_tserver_count = var.YB_TSERVER_COUNT
    yb_shard_replication = var.YB_SHARD_REPLICATION
    yb_transaction_isolation = var.YB_TRANSACTION_ISOLATION
  })
}

# Write to inventory file
resource "local_file" "ansible_inventory" {
  content  = local.inventory_content
  filename = "${path.module}/inventory.ini"
}

resource "local_file" "ansible_vars" {
  content = local.vars_content
  filename = "${path.module}/vars.yml"
}
