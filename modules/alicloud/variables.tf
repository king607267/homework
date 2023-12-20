terraform {
  required_version = "> 0.13.0"
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "1.213.1"
    }
  }
}

variable "alicloud_access_key" {
  default     = ""
  type        = string
  description = "alicloud access key"
}

variable "alicloud_secret_key" {
  default     = ""
  type        = string
  description = "alicloud secret key"
}

variable "public_ip" {}

variable "domain" {}


variable "domain_prefix" {
  default = ""
}