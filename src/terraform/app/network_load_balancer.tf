resource "yandex_lb_target_group" "site-devops-lb-tg" {
  name = "k8s-lb-tg-${terraform.workspace}"
  region_id = "ru-central1"

  dynamic "target" {
    for_each = [for s in yandex_compute_instance.node : {
      address   = s.network_interface.0.ip_address
      subnet_id = s.network_interface.0.subnet_id
    }]
    content {
      subnet_id  = target.value["subnet_id"]
      address = target.value["address"]
    }
  }
  depends_on = [
    yandex_compute_instance.node
  ]
}

resource "yandex_lb_network_load_balancer" "site-devops-lb" {
  name = "k8s-nlb-${terraform.workspace}"

  listener {
    name = "app-${terraform.workspace}"
    port = 80
    target_port = 30000
    external_address_spec {
#          address = yandex_vpc_address.addr-web.external_ipv4_address[0].address
      ip_version = "ipv4"
    }
  }

  listener {
    name = "grafana-${terraform.workspace}"
    port = 3000
    target_port = 30001
    external_address_spec {
#          address = yandex_vpc_address.addr-web.external_ipv4_address[0].address
      ip_version = "ipv4"
    }
  }

  listener {
    name = "jenkins-${terraform.workspace}"
    port = 9000
    target_port = 30002
    external_address_spec {
#          address = yandex_vpc_address.addr-web.external_ipv4_address[0].address
      ip_version = "ipv4"
    }
  }

  listener {
    name = "atlantis-${terraform.workspace}"
    port = 4000
    target_port = 32764
    external_address_spec {
#          address = yandex_vpc_address.addr-web.external_ipv4_address[0].address
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.site-devops-lb-tg.id
    healthcheck {
      name = "http"
      interval            = 10 // Интервал ожидания между проверками работоспособности в секундах.
      timeout             = 5  // Время ожидания ответа до истечения времени проверки работоспособности в секундах.
      unhealthy_threshold = 3  // Количество неудачных проверок работоспособности, прежде чем управляемый экземпляр будет объявлен неработоспособным.
      http_options {
        port = 30000
        path = "/"
      }
    }
  }
}
