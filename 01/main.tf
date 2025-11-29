# Создание сервисного аккаунта для Terraform
resource "yandex_iam_service_account" "service" {
  folder_id     = var.folder_id
  name          = var.account_name
  description   = "Service account"
}

# Назначение роли сервисному аккаунту
resource "yandex_resourcemanager_folder_iam_member" "service-editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.service.id}"
}

# Создание статического ключа доступа
resource "yandex_iam_service_account_static_access_key" "service-keys" {
  service_account_id = yandex_iam_service_account.service.id
  description        = "Static access keys"
}

# Создание бакета с использованием ключа
resource "yandex_storage_bucket" "tf-bucket" {
  access_key = yandex_iam_service_account_static_access_key.service-keys.access_key
  secret_key = yandex_iam_service_account_static_access_key.service-keys.secret_key
  bucket     = var.bucket_name
  folder_id  = var.folder_id
  anonymous_access_flags {
    read = false
    list = false
  }

  force_destroy = true

provisioner "local-exec" {
  command = "echo 'access_key = \"${yandex_iam_service_account_static_access_key.service-keys.access_key}\"' > ../02/backend.conf"
}

provisioner "local-exec" {
  command = "echo 'secret_key = \"${yandex_iam_service_account_static_access_key.service-keys.secret_key}\"' >> ../02/backend.conf"
}
}
