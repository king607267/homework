module "cvm" {
  source        = "../modules/cvm"
  secret_id     = var.secret_id
  secret_key    = var.secret_key
  secret_region = var.secret_region
  cvm_password  = var.cvm_password
  cup           = var.cup
  memory        = var.memory
  instance_name = var.instance_name
}

module "alicloud" {
  source              = "../modules/alicloud"
  public_ip           = module.cvm.public_ip
  alicloud_access_key = var.alicloud_access_key
  alicloud_secret_key = var.alicloud_secret_key
  domain              = var.domain
  domain_prefix       = var.domain_prefix
}

module "k3s" {
  source     = "../modules/k3s"
  public_ip  = module.cvm.public_ip
  private_ip = module.cvm.private_ip
  password   = var.cvm_password
  instance_name = var.instance_name
}

resource "local_sensitive_file" "kubeconfig" {
  content  = module.k3s.kube_config
  filename = "${path.module}/config.yaml"
}

resource "null_resource" "connect_ubuntu" {
  depends_on = [module.k3s]
  connection {
    host     = module.cvm.public_ip
    type     = "ssh"
    user     = "ubuntu"
    password = var.password
    //private_key = file("ssh-key/id_rsa")
    //agent = false
  }

  triggers = {
    script_hash = filemd5("${path.root}/init.sh.tpl")
  }

  provisioner "file" {
    destination = "/tmp/cluster2.yaml"
    content     = templatefile("../cluster2/config.yaml", {})
  }

  provisioner "file" {
    destination = "/tmp/cluster3.yaml"
    content     = templatefile("../cluster3/config.yaml", {})
  }

  provisioner "file" {
    destination = "/tmp/application_set.yaml"
    content     = templatefile("${path.root}/application_set.yaml", {})
  }

  provisioner "file" {
    destination = "/tmp/init.sh"
    content     = templatefile(
      "${path.root}/init.sh.tpl",
      {
        "alidns_access_key" : var.alidns_access_key
        "alidns_secret_key" : var.alidns_secret_key
        "acme_email" : var.acme_email
        "domain" : var.domain
        "public_ip" : module.cvm.public_ip
        "domain_prefix" : var.domain_prefix
      }
    )
  }

  provisioner "remote-exec" {
    # script = "/tmp/init.sh.tpl"
    inline = [
      "chmod +x /tmp/init.sh",
      "sh /tmp/init.sh",
    ]
  }
}