terraform {
  required_version = "> 0.13.0"
  required_providers {
    tencentcloud = {
      source  = "tencentcloudstack/tencentcloud"
      version = "1.81.5"
    }
    alicloud = {
      source  = "aliyun/alicloud"
      version = "1.213.1"
    }
  }
}

variable "cup" {
  default = 2
}

variable "memory" {
  default = 4
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

variable "secret_id" {
  default = "Your Access ID"
}

variable "secret_region" {
  default = "ap-hongkong"
}

variable "secret_key" {
  default = "Your Access key"
}

variable "cvm_password" {
  default = ""
}

variable "instance_name" {
  default = "cluster"
}