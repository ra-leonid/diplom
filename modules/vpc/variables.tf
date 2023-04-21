variable "create_folder" {
  type        = bool
  default     = false
  description = "True/False flag for creation or not folder in your cloud"
}

variable "yc_cloud_id" {
  description = "Cloud id for deplot resources"
  type        = string
  default     = ""
}

variable "yc_folder_id" {
  description = "Folder id for deplot resources"
  type        = string
  default     = ""
}

variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
}

variable "description" {
  description = "An optional description of this resource. Provide this property when you create the resource."
  type        = string
  default     = "Auto-created"
}

variable "subnets" {
  type    = list(object({
    zone           = string
    v4_cidr_blocks = list(string)
  }))
  default = [
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

variable "labels" {
  description = "A set of key/value label pairs to assign."
  type        = map(string)
  default     = {}
}

variable "nat_instance" {
  type    = bool
  default = false
}

variable "nat_instance_zone" {
  description = "The availability zone where the nat-instance will be created."
  type        = string
  default     = "ru-central1-a"
}

variable "nat_username" {
  description = "User to connect to nat-instance."
  type        = string
  default     = "nat_user"
}

variable "nat_id_rsa_pub" {
  description = "The public part of the user's ssh key for connecting to the nat-instance"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}