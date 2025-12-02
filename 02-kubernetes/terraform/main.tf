# Создание сети
resource "yandex_vpc_network" "diplom" {
  name = var.vpc_name
}

# Создание подсетей в разных зонах
resource "yandex_vpc_subnet" "subnet1" {
  name           = var.vpc_subnet.subnet1.name
  zone           = var.vpc_subnet.subnet1.zone
  network_id     = yandex_vpc_network.diplom.id
  v4_cidr_blocks = var.vpc_subnet.subnet1.cidr
}

resource "yandex_vpc_subnet" "subnet2" {
  name           = var.vpc_subnet.subnet2.name
  zone           = var.vpc_subnet.subnet2.zone
  network_id     = yandex_vpc_network.diplom.id
  v4_cidr_blocks = var.vpc_subnet.subnet2.cidr
}

# Создание сервисного аккаунта для управления группой ВМ
resource "yandex_iam_service_account" "groupvm-sa" {
  name        = "groupvm-sa"
  description = "Сервисный аккаунт для управления группой ВМ."
}

# Выдача роли для сервисного аккаунта управления группой ВМ
resource "yandex_resourcemanager_folder_iam_member" "group-editor" {
  folder_id  = var.folder_id
  role       = "editor"
  member     = "serviceAccount:${yandex_iam_service_account.groupvm-sa.id}"
  depends_on = [
    yandex_iam_service_account.groupvm-sa,
  ]
}

data "template_file" "cloudinit" {
 template = file("./cloud-init.yml")
 vars = {
   ssh_public_key = local.ssh_public_key
 }
}

# Определение образа для master
data "yandex_compute_image" "image-master" {
  family = var.instance_resources.master.disk_image
}

# Создание ВМ master
resource "yandex_compute_instance" "master" {
  name                = "master-${count.index + 1}"
  count               = var.instance_resources.master.count
  folder_id           = var.folder_id
  service_account_id  = "${yandex_iam_service_account.groupvm-sa.id}"
  depends_on          = [yandex_resourcemanager_folder_iam_member.group-editor]

  platform_id = var.instance_resources.master.platform_id
  resources {
    memory = var.instance_resources.master.memory
    cores  = var.instance_resources.master.cores
    core_fraction = var.instance_resources.master.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.image-master.image_id
      type     = var.instance_resources.master.disk_type
      size     = var.instance_resources.master.disk_size
    }
  }

  network_interface {
    subnet_id   = yandex_vpc_subnet.subnet1.id
    nat         = var.instance_resources.master.nat
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = local.instance_metadata
}

# Определение образа для worker
data "yandex_compute_image" "image-worker" {
  family = var.instance_resources.worker.disk_image
}

# Создание ВМ worker
resource "yandex_compute_instance" "worker" {
  name                = "worker-${count.index + 1}"
  count               = var.instance_resources.worker.count
  folder_id           = var.folder_id
  service_account_id  = "${yandex_iam_service_account.groupvm-sa.id}"
  depends_on          = [yandex_resourcemanager_folder_iam_member.group-editor]

  platform_id = var.instance_resources.worker.platform_id
  resources {
    memory = var.instance_resources.worker.memory
    cores  = var.instance_resources.worker.cores
    core_fraction = var.instance_resources.worker.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.image-worker.image_id
      type     = var.instance_resources.worker.disk_type
      size     = var.instance_resources.worker.disk_size
    }
  }

  network_interface {
    subnet_id   = yandex_vpc_subnet.subnet1.id
    nat         = var.instance_resources.worker.nat
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = local.instance_metadata
}

# Генерация инвентаря для Kubespray
resource "local_file" "hosts_cfg_kubespray" {
  count = var.exclude_ansible ? 0 : 1

  content = templatefile("./hosts.tftpl", {
    masters = yandex_compute_instance.master
    workers = yandex_compute_instance.worker
  })
  filename = "../kubespray/inventory/mycluster/hosts.yaml"
}

# Создание inventory.ini для ansible
resource "local_file" "ansible_inventory" {
  count = var.exclude_ansible ? 0 : 1

  content = templatefile("${path.module}/inventory.tftpl", {
    masters = yandex_compute_instance.master
    workers = yandex_compute_instance.worker
  })
  filename = "./scripts/inventory.ini"
}

# Запуск kubespray для настройки K8S кластера
resource "null_resource" "run_kubespray" {
  depends_on = [
    local_file.ansible_inventory
  ]

  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}/../kubespray && \
      ansible-playbook -i inventory/mycluster/hosts.yaml \
        -u ubuntu \
        --become --become-user=root \
        -e "kubeconfig_localhost=true" \
        cluster.yml \
        --flush-cache
    EOT
  }
}