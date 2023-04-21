module "vpc" {
#  source  = "ra-leonid/vpc/yandex"
  source  = "github.com/ra-leonid/vpc/yandex"
  version = "0.2.1"
  description = "managed by terraform"
  create_folder = length(var.yc_folder_id) > 0 ? false : true
  yc_folder_id = var.yc_folder_id
  nat_instance = true
  name = "k8s-${terraform.workspace}"
  subnets = local.vpc_subnets[terraform.workspace]
}

locals {
  name_set = {
    control_plane = "control-plane"
    node = "node"
  }
  instance = {
    stage = var.stage_instance
    prod = var.prod_instance
  }
  vpc_subnets = {
    stage = [
      {
        "zone": var.yc_region
        v4_cidr_blocks = ["10.127.0.0/24"]
      }
    ]
    prod = [
      {
        zone           = "ru-central1-a"
        v4_cidr_blocks = ["10.130.0.0/24"]
      },
      {
        zone           = "ru-central1-b"
        v4_cidr_blocks = ["10.129.0.0/24"]
      },
      {
        zone           = "ru-central1-c"
        v4_cidr_blocks = ["10.128.0.0/24"]
      }
    ]
  }
}
