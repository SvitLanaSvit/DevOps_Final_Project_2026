locals {
  argocd_hostname = "argocd.${local.domain_name}"
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true

  # Enable ingress for ArgoCD (Argo Continuous Delivery)
  set {
    name  = "server.ingress.enabled"
    value = "true"
  }

  # Use nginx ingress controller installed earlier
  set {
    name  = "server.ingress.ingressClassName"
    value = "nginx"
  }

  # Public hostname (FQDN – Fully Qualified Domain Name) for ArgoCD UI
  # global.domain керує доменом для всіх компонентів ArgoCD
  set {
    name  = "global.domain"
    value = local.argocd_hostname
  }

  # Дублюємо для надійності на рівні самого ingress
  set {
    name  = "server.ingress.hostname"
    value = local.argocd_hostname
  }

  # ArgoCD server will listen over HTTP inside the cluster,
  # TLS (Transport Layer Security) is terminated at AWS NLB (Network Load Balancer) using ACM (AWS Certificate Manager)
  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }

  depends_on = [
    aws_eks_cluster.danit,
    aws_eks_node_group.danit,
    helm_release.nginx_ingress,
  ]
}
