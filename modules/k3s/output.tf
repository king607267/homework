output "kube_config" {
  description = "kubeconfig"
  value       = "${path.module}/config.yaml"
}

output "kubernetes" {
  value = module.k3s.kubernetes
}