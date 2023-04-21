variable "url" {
  default = "meow-app.duckdns.org"
}

variable "yc_key_file" {
  default = ".secrets/.key.json"
}

variable "id_rsa_pub" {
  default = ""
}

variable "yc_token" {
  default = ""
  type = string
  sensitive = true
}

variable "yc_cloud_id" {
  default = ""
  type = string
  sensitive = true
}

variable "yc_folder_id" {
  default = ""
  type = string
  sensitive = true
}

variable "yc_region" {
  default = "ru-central1-a"
}

variable "image" {
  default = "ubuntu-2004-lts"
}

variable "tf_user" {
  default = "ubuntu"
}

variable "stage_instance" {
  default = {
    control_plane = {
      count = 1
      cores = 2
      disk_size = 50
      memory = 4
    }
    node = {
      count = 1
      cores = 2
      disk_size = 200
      memory = 4
    }
  }
  description = "Инфраструктура k8s-кластера для stage"
}

variable "prod_instance" {
  default = {
    control_plane = {
      count = 3
      cores = 2
      disk_size = 20
      memory = 2
    }
    node = {
      count = 3
      cores = 2
      disk_size = 40
      memory = 2
    }
  }
  description = "Инфраструктура k8s-кластера для prod"
}

