variable "secret_id" {
  default = ""
}

variable "secret_region" {
  default = "ap-hongkong"
}

variable "secret_key" {
  default = ""
}

variable "cvm_password" {
  default = ""
}

variable "alidns_access_key" {
  default     = ""
  description = "alidns access key"
}

variable "alidns_secret_key" {
  description = "alidns access key"
}

variable "alicloud_access_key" {
  description = "alicloud access key"
}

variable "alicloud_secret_key" {
  description = "alicloud secret key"
}

variable "acme_email" {
  description = "cert-manager acme email"
}

variable "domain" {
  default     = ""
  type        = string
  description = "domain"
}

variable "domain_prefix" {
  default = "cvm1"
}

variable "cup" {
  default = 2
}

variable "memory" {
  default = 4
}

variable "password" {
  default = ""
}

variable "instance_name" {
  default = "cluster1"
}