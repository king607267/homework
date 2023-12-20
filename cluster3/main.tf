module "cvm" {
  source        = "../modules/cvm"
  secret_id     = var.secret_id
  secret_key    = var.secret_key
  secret_region = var.secret_region
  cup           = var.cup
  cvm_password  = var.cvm_password
  memory        = var.memory
  instance_name = var.instance_name
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
    password = var.cvm_password
    //private_key = file("ssh-key/id_rsa")
    //agent = false
  }

  triggers = {
    script_hash = filemd5("${path.root}/init.sh.tpl")
  }

  provisioner "file" {
    destination = "/tmp/init.sh"
    content     = templatefile(
      "${path.root}/init.sh.tpl", {}
    )
  }
#
#  provisioner "remote-exec" {
#    # script = "/tmp/init.sh.tpl"
#    inline = [
#      "chmod +x /tmp/init.sh",
#      "sh /tmp/init.sh",
#    ]
#  }
}