# Provider
provider "yandex" {
  # Only one of token or service_account_key_file must be specified.
  # token     = var.yc_token
  service_account_key_file = var.yc_key_file
  folder_id = var.yc_folder_id
  cloud_id  = var.yc_cloud_id
  zone      = var.yc_region

}
