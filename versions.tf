terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.88.0"
    }
  }
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "ra-leonid"

    workspaces {
      #name = "terraform-cloud"
      prefix = "diplom-"
    }
  }
}
