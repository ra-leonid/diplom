---
all:
  hosts:
%{ for ip in all_k8s_nodes ~}
    node${index(all_k8s_nodes, ip) + 1}:
      ansible_host: ${ip}
      ansible_user: ${tf_user}
%{ endfor ~}
  children:
    bastion:
      hosts:
        bastion:
          ansible_host: ${ip_bastion}
          ansible_user: ${tf_user}
    kube_control_plane:
      hosts:
%{ for ip in control_plane_nodes ~}
        node${index(all_k8s_nodes, ip) + 1}:
%{ endfor ~}
    kube_node:
      hosts:
%{ for ip in slave_nodes ~}
        node${index(all_k8s_nodes, ip) + 1}:
%{ endfor ~}
  vars:
    ansible_ssh_common_args: "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand=\"ssh -W %h:%p ${tf_user}@${ip_bastion} -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null\""