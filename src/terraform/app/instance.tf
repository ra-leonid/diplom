variable count_format { default = "%01d" } #server number format (-1, -2, etc.)

data "yandex_compute_image" "image" {
  family = var.image
}

resource "yandex_compute_instance" "control-plane" {
  count = local.instance[terraform.workspace]["control_plane"].count
  name = "k8s-control-plane-${format(var.count_format, count.index+1)}"
  hostname = "k8s-control-plane-${format(var.count_format, count.index+1)}"
  zone     = element(keys(module.vpc.subnets)[*], count.index % length(keys(module.vpc.subnets)))

  resources {
    cores  = local.instance[terraform.workspace]["control_plane"].cores
    memory = local.instance[terraform.workspace]["control_plane"].memory
    core_fraction = "100"
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.image.id
      type = "network-hdd"
      size = local.instance[terraform.workspace]["control_plane"].disk_size
    }
  }
  network_interface {
    subnet_id     = module.vpc.subnets[element(keys(module.vpc.subnets)[*], count.index % length(keys(module.vpc.subnets)))].id
    nat       = false
  }

  metadata = {
    ssh-keys = "${var.tf_user}:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_compute_instance" "node" {
  count = local.instance[terraform.workspace]["node"].count
  name = "k8s-node-${format(var.count_format, count.index+1)}"
  hostname = "k8s-node-${format(var.count_format, count.index+1)}"
  zone     = element(keys(module.vpc.subnets)[*], count.index % length(keys(module.vpc.subnets)))

  resources {
    cores  = local.instance[terraform.workspace]["node"].cores
    memory = local.instance[terraform.workspace]["node"].memory
    core_fraction = "100"
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.image.id
      type = "network-hdd"
      size = local.instance[terraform.workspace]["node"].disk_size
    }
  }
  network_interface {
    subnet_id     = module.vpc.subnets[element(keys(module.vpc.subnets)[*], count.index % length(keys(module.vpc.subnets)))].id
    nat       = false
  }

  metadata = {
    ssh-keys = "${var.tf_user}:${file("~/.ssh/id_rsa.pub")}"
  }
}
