variable "bucket_name" {
  type        = string
  default     = "glubuchik-diplom"
  description = "bucket name"
}

variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}

variable "vpc_name" {
  type        = string
  default     = "develop"
  description = "VPC network&subnet name"
}

variable "vpc_subnet" {
  type        = map(object({
    name = string,
    zone = string,
    cidr = list(string)
    }))
  default     = {
    default = {
      name = "default",
      zone = "ru-central1-a",
      cidr = ["10.0.1.0/24"]
      }}
  description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
}

variable "image" {
  description = "Path to the image file"
  type        = object({
    name = string,
    path = string
  })
  default     = {
    name = "1.jpeg",
    path = "./1.jpeg"
  }
}


variable "instance_resources" {
  type        = map(object({
    name          = string,
    count         = number,
    platform_id   = string,
    cores         = number,
    memory        = number,
    core_fraction = number,
    disk_image    = string,
    disk_type     = string,
    disk_size     = number,
    nat           = bool
  }))
  default     = {
    master = {
        name            = "master",
        count           = 1,
        platform_id     = "standard-v1",
        cores           = 2, 
        memory          = 4, 
        core_fraction   = 5,
        disk_image      = "ubuntu-2004-lts",
        disk_type       = "network-hdd",
        disk_size       = 10,
        nat             = true
    }
    worker = {
        name            = "worker",
        count           = 2,
        platform_id     = "standard-v1",
        cores           = 4, 
        memory          = 8, 
        core_fraction   = 5,
        disk_image      = "ubuntu-2004-lts",
        disk_type       = "network-hdd",
        disk_size       = 10,
        nat             = true
    }}
  description = "instance_group"
}

variable "exclude_ansible" {
  description = "Флаг для исключения ansible.tf"
  type        = bool
  default     = false
}