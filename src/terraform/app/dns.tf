resource "yandex_vpc_address" "addr-web" {
  name = "webtestappAddress"

  external_ipv4_address {
    zone_id = "ru-central1-a"
  }
}

resource "yandex_dns_zone" "dns_zone" {
  name        = "app-${terraform.workspace}"
  zone             = "${var.url}."
  public           = true
}

resource "yandex_dns_recordset" "rs-a" {
  zone_id = yandex_dns_zone.dns_zone.id
  name    = "${var.url}."
  type    = "A"
  ttl     = 5
  data    = ["${yandex_vpc_address.addr-web.external_ipv4_address[0].address}"]

  depends_on = [
    yandex_dns_zone.dns_zone
  ]
}
#
#resource "yandex_dns_recordset" "rs-grafana" {
#  zone_id = yandex_dns_zone.dns_zone.id
#  name    = "grafana"
#  type    = "CNAME"
#  ttl     = 30
#  data    = ["${var.url}"]
#
#  depends_on = [
#    yandex_dns_zone.dns_zone
#  ]
#}
#
#resource "yandex_dns_recordset" "rs-app" {
#  zone_id = yandex_dns_zone.dns_zone.id
#  name    = "*"
#  type    = "CNAME"
#  ttl     = 5
#  data    = ["${var.url}"]
#
#  depends_on = [
#    yandex_dns_zone.dns_zone
#  ]
#}
