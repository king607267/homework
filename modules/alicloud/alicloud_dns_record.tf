provider "alicloud" {
  access_key = "${var.alicloud_access_key}"
  secret_key = "${var.alicloud_secret_key}"
  region     = "cn-beijing"
}

# https://registry.terraform.io/providers/aliyun/alicloud/latest/docs
# https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/dns_record
resource "alicloud_dns_record" "bookinfo" {
  name        = var.domain
  host_record = "${var.domain_prefix}.bookinfo"
  type        = "A"
  value       = var.public_ip
}

resource "alicloud_dns_record" "jenkins" {
  name        = var.domain
  host_record = "${var.domain_prefix}.jenkins"
  type        = "A"
  value       = var.public_ip
}

resource "alicloud_dns_record" "argocd" {
  name        = var.domain
  host_record = "${var.domain_prefix}.argocd"
  type        = "A"
  value       = var.public_ip
}
