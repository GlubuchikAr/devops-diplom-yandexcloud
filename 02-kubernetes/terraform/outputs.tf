output "master_ips" {
  value = {
    for idx, master in yandex_compute_instance.master :
    master.name => master.network_interface[0].nat_ip_address
  }
}

output "worker_ips" {
  value = {
    for idx, worker in yandex_compute_instance.worker :
    worker.name => worker.network_interface[0].nat_ip_address
  }
}

output "ansible_inventory_created" {
  value = var.exclude_ansible ? false : true
}

output "ssh_connection_commands" {
  value = [
    for master in yandex_compute_instance.master :
    "ssh ubuntu@${master.network_interface[0].nat_ip_address}"
  ]
}