all:
  hosts:
%{ for ip in all_k8s_nodes ~}
    node${index(all_k8s_nodes, ip) + 1}:
      ansible_host: ${ip}
      #ip: ${ip}
      #access_ip: ${ip}
      ansible_user: ${tf_user}
      ansible_ssh_private_key_file: $HOME/.ssh/id_rsa.pub
      ansible_ssh_user: ${tf_user}
%{ endfor ~}
  children:
    bastion:
      hosts:
        bastion:
          ansible_host: ${ip_bastion}
          ansible_user: ${tf_user}
          ansible_ssh_private_key_file: $HOME/.ssh/id_rsa.pub
          ansible_ssh_user: ${tf_user}
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
    etcd:
      hosts:
%{ for ip in control_plane_nodes ~}
        node${index(all_k8s_nodes, ip) + 1}:
%{ endfor ~}
    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:
    calico_rr:
      hosts: {}
