#resource "local_file" "inventory" {
#  content = templatefile("templates/inventory.tpl",
#    {
#      all_k8s_nodes = flatten([
#        [for instance in yandex_compute_instance.control-plane : instance.network_interface.0.ip_address],
#        [for instance in yandex_compute_instance.node : instance.network_interface.0.ip_address]
#      ])
#      control_plane_nodes = [for instance in yandex_compute_instance.control-plane : instance.network_interface.0.ip_address]
#      slave_nodes = [for instance in yandex_compute_instance.node : instance.network_interface.0.ip_address]
#
#      tf_user = var.tf_user
#      ip_bastion = module.vpc.nat_ip_address
#    }
#  )
#
#  filename = "src/playbook/inventory.yml"
#
#  depends_on = [
#    yandex_compute_instance.control-plane
#  ]
#}

#resource "local_file" "group_vars_localhost" {
#  content = templatefile("templates/group_vars_localhost.tpl",
#    {
#      namespace = terraform.workspace
#      url: var.url
#    }
#  )
#  filename = "src/playbook/group_vars/all/localhost/vars.yml"
#
#  depends_on = [
#    yandex_compute_instance.control-plane
#  ]
#}

output "inventory" {
  value = templatefile("templates/inventory.tpl",
    {
      all_k8s_nodes = flatten([
        [for instance in yandex_compute_instance.control-plane : instance.network_interface.0.ip_address],
        [for instance in yandex_compute_instance.node : instance.network_interface.0.ip_address]
      ])
      control_plane_nodes = [for instance in yandex_compute_instance.control-plane : instance.network_interface.0.ip_address]
      slave_nodes = [for instance in yandex_compute_instance.node : instance.network_interface.0.ip_address]

      tf_user = var.tf_user
      ip_bastion = module.vpc.nat_ip_address
    }
  )

  depends_on = [
    yandex_compute_instance.control-plane
  ]
}

        
output "group_vars_localhost" {
  value = templatefile("templates/group_vars_localhost.tpl",
    {
      namespace = terraform.workspace
      url: var.url
    }
  )

  depends_on = [
    yandex_compute_instance.control-plane
  ]
}
