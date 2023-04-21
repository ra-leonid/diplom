#
#resource "yandex_alb_target_group" "k8s-alb-tg" {
#  name = "${terraform.workspace}-k8s-alb-target-group"
#
#  dynamic "target" {
#    for_each = [for s in yandex_compute_instance.node : {
#      address   = s.network_interface.0.ip_address
#      subnet_id = s.network_interface.0.subnet_id
#    }]
#    content {
#      subnet_id  = target.value["subnet_id"]
#      ip_address = target.value["address"]
#    }
#  }
#  depends_on = [
#    yandex_compute_instance.node
#  ]
#}
#
#resource "yandex_alb_backend_group" "k8s-backend-group-app" {
#  name = "${terraform.workspace}-k8s-bg-app"
#
#  http_backend {
#    name             = "${terraform.workspace}-k8s-http-backend-app"
#    weight           = 1
#    port             = 30000
#    target_group_ids = ["${yandex_alb_target_group.k8s-alb-tg.id}"]
#    load_balancing_config {
#      panic_threshold = 50
#    }
#    healthcheck {
#      timeout             = "1s"
#      interval            = "1s"
#      healthy_threshold   = 1
#      unhealthy_threshold = 3
#      healthcheck_port    = 30000
#      http_healthcheck {
#        path = "/"
#      }
#    }
#  }
#
#  depends_on = [
#    yandex_alb_target_group.k8s-alb-tg
#  ]
#}
#
##resource "yandex_alb_backend_group" "k8s-backend-group-grafana" {
##  name = "${terraform.workspace}-k8s-bg-grafana"
##
##  http_backend {
##    name             = "${terraform.workspace}-k8s-http-backend-grafana"
##    weight           = 1
##    port             = 30001
##    target_group_ids = ["${yandex_alb_target_group.k8s-alb-tg.id}"]
##    load_balancing_config {
##      panic_threshold = 50
##    }
##    healthcheck {
##      timeout             = "1s"
##      interval            = "1s"
##      healthy_threshold   = 1
##      unhealthy_threshold = 3
##      healthcheck_port    = 30001
##      http_healthcheck {
##        path = "/login"
##      }
##    }
##  }
#
#resource "yandex_alb_http_router" "k8s-tf-router" {
#  name = "${terraform.workspace}-k8s-http-router"
#}
#
#resource "yandex_alb_virtual_host" "k8s-virtual-host" {
#  name           = "${terraform.workspace}-k8s-virtual-host"
#  http_router_id = yandex_alb_http_router.k8s-tf-router.id
#  route {
#    name = "${terraform.workspace}-k8s-http-route-app"
#    http_route {
#      http_match {
#        path {
##          exact = "/"
##          prefix = "/"
#
##          exact = "grafana.meow-app.duckdns.org"
#
#          #          prefix = "grafana."
##          prefix = "grafana/"
##          regex = "app.*"
##          prefix = "grafana"
#          prefix = "/grafana/"
##          exact = "grafana.meow-app.duckdns.org"
##          exact = "meow-app.duckdns.org"
##          exact = "meow-app.duckdns.org"
##          prefix = "*.grafana"
##          prefix = "/grafana"
#        }
#      }
#      http_route_action {
#        backend_group_id = yandex_alb_backend_group.k8s-backend-group-app.id
#        timeout          = "3s"
#      }
#    }
#  }
#
##  route {
##    name = "${terraform.workspace}-k8s-http-route-grafana"
##    http_route {
##      http_match {
##        path {
##          prefix = "/"
###          prefix = "/grafana"
###          prefix = "grafana.meow-app.duckdns.org"
###          exact = "grafana.meow-app.duckdns.org"
##        }
##      }
##      http_route_action {
##        backend_group_id = yandex_alb_backend_group.k8s-backend-group-grafana.id
##        timeout          = "3s"
##      }
##    }
##  }
#  depends_on = [
#    yandex_alb_http_router.k8s-tf-router,
#    yandex_alb_backend_group.k8s-backend-group-app,
##    yandex_alb_backend_group.k8s-backend-group-grafana
#  ]
#}
#
#
#resource "yandex_alb_load_balancer" "k8s-alb-balancer" {
#  name = "${terraform.workspace}-k8s-load-balancer"
#  network_id = module.vpc.network_id
#
#  allocation_policy {
#    dynamic "location" {
#      for_each = [for s in module.vpc.subnets : {
#        zone_id   = s["zone"]
#        subnet_id = s["id"]
#      }]
#
#      content {
#        subnet_id = location.value.subnet_id
#        zone_id   = location.value.zone_id
#      }
#    }
#  }
#
#  listener {
#    name = "${terraform.workspace}-k8s-listener"
#    endpoint {
#      address {
#        external_ipv4_address {
#          address = yandex_vpc_address.addr-web.external_ipv4_address[0].address
#        }
#      }
#      ports = [80]
#    }
#    http {
#      handler {
#        http_router_id = yandex_alb_http_router.k8s-tf-router.id
#      }
#    }
#  }
#  depends_on = [
#    yandex_vpc_address.addr-web,
#    yandex_alb_http_router.k8s-tf-router,
#    yandex_alb_virtual_host.k8s-virtual-host
#  ]
#}