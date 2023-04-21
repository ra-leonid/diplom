#resource "local_file" "inventory" {
#  content = templatefile("templates/inventory.tpl",
#    {
##      ip_control_plane = yandex_compute_instance.control-plane[0].network_interface.0.ip_address
##      bastion = module.vpc.nat_ip_address
##      ansible_user = var.tf_user
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
#
#resource "local_file" "qbec_group_vars_localhost" {
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
#
##resource "null_resource" "setting_up_access" {
##  provisioner "local-exec" {
##    command = "ANSIBLE_FORCE_COLOR=1 ansible-playbook -i inventory.yml --private-key ~/.ssh/id_rsa -e '{\"ansible_ssh_common_args\":\"-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand=\\\"ssh -W %h:%p ${var.tf_user}@${module.vpc.nat_ip_address} -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null\\\"\"}' configuring_access_to_k8s.yml"
##    working_dir = "../../playbook"
##  }
##
##  depends_on = [
##    null_resource.kubespray,
##    local_file.inventory
##  ]
##}
##
##resource "null_resource" "configuration_qbec" {
##  provisioner "local-exec" {
##    command = "ANSIBLE_FORCE_COLOR=1 ansible-playbook -i inventory.yml configuration_qbec.yml"
##    working_dir = "../../playbook"
##  }
##
##  depends_on = [
##    null_resource.kubespray,
##    local_file.qbec_group_vars_localhost,
##    null_resource.setting_up_access
##  ]
##}
