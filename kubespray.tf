#resource "local_file" "kuberspray_inventory" {
#  content = templatefile("templates/hosts.tpl",
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
#  filename = "src/vendor/kubespray/inventory/mycluster/hosts.yaml"
#
#  depends_on = [
#    yandex_compute_instance.control-plane,
#    yandex_compute_instance.node
#  ]
#}

output "kuberspray_inventory" {
  value = templatefile("templates/hosts.tpl",
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
    yandex_compute_instance.control-plane,
    yandex_compute_instance.node
  ]
}
