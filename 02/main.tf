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

# Определение образа для master
data "yandex_compute_image" "image-master" {
  family = var.instance_group.master.disk_image
}

# Создание ВМ master
resource "yandex_compute_instance" "master" {
  name                = "${var.instance_group.master.name}-${count.index + 1}"
  count               = var.instance_group.master.fixed_scale
  folder_id           = var.folder_id
  service_account_id  = "${yandex_iam_service_account.groupvm-sa.id}"
  depends_on          = [yandex_resourcemanager_folder_iam_member.group-editor]

  platform_id = var.instance_group.master.platform_id
  resources {
    memory = var.instance_group.master.memory
    cores  = var.instance_group.master.cores
    core_fraction = var.instance_group.master.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.master.image_id
      type     = var.instance_group.master.disk_type
      size     = var.instance_group.master.disk_size
    }
  }

  network_interface {
    subnet_id   = yandex_vpc_subnet.subnet1.id
    nat         = var.instance_group.master.nat
  }

  scheduling_policy {
    preemptible = true
  }

  metadata = local.instance_metadata
}

# Определение образа для worker
data "yandex_compute_image" "image-worker" {
  family = var.instance_group.worker.disk_image
}

# Создание группы ВМ worker
resource "yandex_compute_instance_group" "group-worker" {
  name                = var.instance_group.worker.name
  folder_id           = var.folder_id
  service_account_id  = "${yandex_iam_service_account.groupvm-sa.id}"
  deletion_protection = "false"
  depends_on          = [yandex_resourcemanager_folder_iam_member.group-editor]

  instance_template {
    platform_id = var.instance_group.worker.platform_id
    resources {
      memory = var.instance_group.worker.memory
      cores  = var.instance_group.worker.cores
      core_fraction = var.instance_group.worker.core_fraction
    }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.worker.image_id
      type     = var.instance_group.worker.disk_type
      size     = var.instance_group.worker.disk_size
    }
  }

  network_interface {
    network_id         = "${yandex_vpc_network.diplom.id}"
    subnet_ids         = ["${yandex_vpc_subnet.subnet1.id}"]
    nat = var.instance_group.worker.nat
  }

  scheduling_policy {
    preemptible = true
  }

    metadata = local.instance_metadata
  }

  scale_policy {
    fixed_scale {
      size = var.instance_group.worker.count
    }
  }

  allocation_policy {
    zones = [var.default_zone]
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 0
  }

  health_check {
    interval = 30
    timeout  = 10
    tcp_options {
      port = 80
    }
  }

  load_balancer {
      target_group_name = "worker"
  }
}
