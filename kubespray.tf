resource "local_file" "kuberspray_inventory" {
  content = templatefile("templates/hosts.tpl",
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
  filename = "src/vendor/kubespray/inventory/mycluster/hosts.yaml"

  depends_on = [
    yandex_compute_instance.control-plane,
    yandex_compute_instance.node
  ]
}

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

#
#resource "null_resource" "wait" {
#  provisioner "local-exec" {
#    command = "sleep 100"
#  }
#
#  depends_on = [
#    local_file.kuberspray_inventory
#  ]
#}
#
#resource "null_resource" "kubespray" {
#  provisioner "local-exec" {
#    command = "ANSIBLE_FORCE_COLOR=1 ansible-playbook -i ./inventory/mycluster/hosts.yaml --become --become-user=root --extra-vars \"{ \\\"supplementary_addresses_in_ssl_keys\\\":${jsonencode(module.all_nodes["control_plane"].external_ip_address_instance)}}\" cluster.yml"
#    working_dir = "../../vendor/kubespray"
#  }
#
#  depends_on = [
#    null_resource.wait
#  ]
#}