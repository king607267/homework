module "k3s" {
  source                   = "xunleii/k3s/module"
  k3s_version              = "v1.25.11+k3s1"
  generate_ca_certificates = true
  global_flags             = [
    "--tls-san ${var.public_ip}",
    "--write-kubeconfig-mode 644",
    "--disable=traefik",
    "--kube-controller-manager-arg bind-address=0.0.0.0",
    "--kube-proxy-arg metrics-bind-address=0.0.0.0",
    "--kube-scheduler-arg bind-address=0.0.0.0"
  ]
  k3s_install_env_vars = {}
  cluster_domain = var.instance_name
  servers = {
    "k3s" = {
      ip         = var.private_ip
      connection = {
        timeout  = "60s"
        type     = "ssh"
        host     = var.public_ip
        password = var.password
        user     = "ubuntu"
      }
    }
  }
}

resource "local_sensitive_file" "kubeconfig" {
  content  = module.k3s.kube_config
  filename = "${path.root}/config.yaml"
}