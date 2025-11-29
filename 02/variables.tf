variable "bucket_name" {
  type        = string
  default     = "glubuchik-diplom"
  description = "bucket name"
}

variable "s3_access_key" {
  description = "Yandex Cloud Storage access key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "s3_secret_key" {
  description = "Yandex Cloud Storage secret key"
  type        = string
  sensitive   = true
  default     = ""
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


variable "instance_group" {
  type        = map(object({
    name          = string,
    fixed_scale   = number,
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
    default = {
      name          = "default",
      count         = 1,
      platform_id   = "standard-v1",
      cores         = 2, 
      memory        = 1, 
      core_fraction = 5,
      disk_image    = "fd80mrhj8fl2oe87o4e1",
      disk_type     = "network-hdd",
      disk_size     = 10,
      nat           = true
      }}
  description = "instance_group"
}