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

variable "cup" {
  default = 2
}

variable "memory" {
  default = 2
}

variable "domain" {}


variable "domain_prefix" {
  default = "cvm2"
}

variable "alicloud_access_key" {
  description = "alicloud access key"
}

variable "alicloud_secret_key" {
  description = "alicloud secret key"
}

variable "instance_name" {
  default = "cluster2"
}