# Yandex Cloud VPC module
This module creates folder in your cloud if needed (create_folder = true) and add next resources:
- VPC + Network + Subnets
- Nat Instance if needed
- Route tables if needed

> Attention! This module forked from https://github.com/shestera/terraform-yandex-vpc because origin is not supported or slowly supported.


## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.1.0 |
| yandex | ~> 0.88.0 |

## Providers

| Name | Version |
|------|---------|
| yandex | ~> 0.88.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_folder | Create or not folder. If you have not create folder and use currently please set yc_folder_id.| `bool` | `false` | yes |
| yc_folder_id | Folder id for provide resources. Set this variable for disable auto creation it.| `string` | `` | no |
| description | An optional description of this resource. Provide this property when you create the resource. | `string` | `"Auto-created"` | no |
| labels | A set of key/value label pairs to assign. | `map(string)` | `{}` | no |
| name | Name to be used on all the resources as identifier | `string` | n/a | yes |
| nat\_instance | n/a | `bool` | `false` | no |
| nat\_instance\_zone | The availability zone where the nat-instance will be created. | `string` | `"ru-central1-a"` | no |
| nat\_username | User to connect to nat-instance. | `string` | `nat_user` | no |
| nat\_id\_rsa\_pub | The public part of the user's ssh key for connecting to the nat-instance | `string` | `~/.ssh/id_rsa.pub` | no |
| subnets | n/a | <pre>list(object({<br>    zone           = string<br>    v4_cidr_blocks = list(string)<br>  }))</pre> | <pre>[<br>  {<br>    "v4_cidr_blocks": [<br>      "10.130.0.0/24"<br>    ],<br>    "zone": "ru-central1-a"<br>  },<br>  {<br>    "v4_cidr_blocks": [<br>      "10.129.0.0/24"<br>    ],<br>    "zone": "ru-central1-b"<br>  },<br>  {<br>    "v4_cidr_blocks": [<br>      "10.128.0.0/24"<br>    ],<br>    "zone": "ru-central1-c"<br>  }<br>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| network\_id | The ID of the VPC |
| subnet\_ids | n/a |
| subnet\_zones | n/a |
| subnets | n/a |
| folder_id | The ID of created Folder |
| nat_ip_address | n/a |
| nat_username | n/a |

## Usage

Sample main.tf: 

```hcl
terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.88.0"
    }
  }
}

# Provider
provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  zone      = var.yc_region
}


module "vpc" {
  source  = "hamnsk/vpc/yandex"
  version = "0.5.0"
  description = "managed by terraform"
  create_folder = length(var.yc_folder_id) > 0 ? false : true
  name = terraform.workspace
  subnets = local.vpc_subnets[terraform.workspace]
}



locals {
  vpc_subnets = {
    stage = [
      {
        "v4_cidr_blocks": [
          "10.128.0.0/24"
        ],
        "zone": var.yc_region
      }
    ]
    prod = [
      {
        zone           = "ru-central1-a"
        v4_cidr_blocks = ["10.128.0.0/24"]
      },
      {
        zone           = "ru-central1-b"
        v4_cidr_blocks = ["10.129.0.0/24"]
      },
      {
        zone           = "ru-central1-c"
        v4_cidr_blocks = ["10.130.0.0/24"]
      }
    ]
  }
}

```


Sample variables.tf:

```hcl
variable "yc_token" {
   default = ""
}

variable "yc_cloud_id" {
  default = ""
}

variable "yc_folder_id" {
  default = ""
}

variable "yc_region" {
  default = "ru-central1-a"
}

```
