resource "yandex_resourcemanager_folder" "folder" {
  count = var.create_folder ? 1 : 0
  cloud_id = var.yc_cloud_id
  name = terraform.workspace
  description = "terraform managed"
}

resource "yandex_vpc_network" "this" {
  name        = var.name
  description = "${var.description} ${var.name} network"
  folder_id   = var.create_folder ? yandex_resourcemanager_folder.folder[0].id : var.yc_folder_id

  labels = var.labels
  depends_on = [
    yandex_resourcemanager_folder.folder
  ]
}

resource "yandex_vpc_subnet" "public" {
  count          = var.nat_instance ? 1 : 0
  name           = "${var.name}-public"
  v4_cidr_blocks = ["10.100.0.0/24"]
  zone           = var.nat_instance_zone
  network_id     = yandex_vpc_network.this.id
  labels         = var.labels

  depends_on = [
    yandex_vpc_network.this
  ]
}

data "yandex_compute_image" "nat_instance" {
  family = "nat-instance-ubuntu"
}

resource "yandex_compute_instance" "nat_instance" {
  count = var.nat_instance ? 1 : 0

  name        = "${var.name}-nat-instance"
  hostname    = "${var.name}-nat-instance"
  platform_id = "standard-v2"
  zone        = var.nat_instance_zone

  labels = var.labels

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.nat_instance.id
    }
  }

  network_interface {
    nat       = true
    subnet_id = yandex_vpc_subnet.public[0].id
  }

  metadata = {
    ssh-keys = "${var.nat_username}:${file(var.nat_id_rsa_pub)}"
  }

  depends_on = [
    yandex_vpc_subnet.public
  ]
}

resource "yandex_vpc_route_table" "nat_instance" {
  count = var.nat_instance ? 1 : 0

  network_id = yandex_vpc_network.this.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = yandex_compute_instance.nat_instance[0].network_interface.0.ip_address
  }

  depends_on = [
    yandex_compute_instance.nat_instance
  ]
}

resource "yandex_vpc_subnet" "this" {
  for_each       = {for z in var.subnets : z.zone => z}
  name           = "${var.name}-${each.value.zone}"
  description    = "${var.description} ${var.name} subnet for zone ${each.value.zone}"
  v4_cidr_blocks = each.value.v4_cidr_blocks
  zone           = each.value.zone
  network_id     = yandex_vpc_network.this.id
  labels         = var.labels
  folder_id      = var.create_folder ? yandex_resourcemanager_folder.folder[0].id : var.yc_folder_id

  route_table_id = var.nat_instance ? yandex_vpc_route_table.nat_instance[0].id : null

  depends_on = [
    yandex_vpc_network.this,
    yandex_vpc_route_table.nat_instance
  ]
}