/* Встановлюємо ArgoCD через Helm, налаштовуючи Ingress для доступу до UI через NLB з TLS термінацією на основі ACM сертифіката. */

/* Локальна змінна для формування повного доменного імені для ArgoCD, яке буде використовуватися в налаштуваннях Ingress. */
locals {
  argocd_hostname = "argocd.${local.domain_name}"
}

/* Ресурс `helm_release` для встановлення ArgoCD:
- `name`: Ім'я релізу Helm.
- `repository`: URL репозиторію Helm, де знаходиться чарт для ArgoCD.
- `chart`: Назва чарта для встановлення.
- `version`: Версія чарта, яку ми хочемо встановити.
- `namespace`: Kubernetes namespace, де буде встановлено ArgoCD.
- `create_namespace`: Якщо true, Terraform створить namespace, якщо він ще не існує. */
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true

  /* Налаштовуємо Ingress для ArgoCD, щоб забезпечити доступ до UI через NLB з TLS термінацією на основі ACM сертифіката.
  - `server.ingress.enabled`: Включає Ingress для ArgoCD server. */
  set {
    name  = "server.ingress.enabled"
    value = "true"
  }

  /* Вказуємо клас Ingress, який буде використовуватися для ArgoCD. У цьому випадку ми використовуємо "nginx", оскільки ми встановили nginx-ingress як Ingress Controller. */
  set {
    name  = "server.ingress.ingressClassName"
    value = "nginx"
  }

  /* Публічне доменне ім'я (FQDN – Fully Qualified Domain Name) для ArgoCD UI */
  /* global.domain керує доменом для всіх компонентів ArgoCD */
  set {
    name  = "global.domain"
    value = local.argocd_hostname
  }

  /* Дублюємо для надійності на рівні самого ingress */
  set {
    name  = "server.ingress.hostname"
    value = local.argocd_hostname
  }

  /* Додаткові аргументи для ArgoCD server, які можуть бути корисними для налаштування безпеки або інших параметрів. У цьому випадку ми додаємо аргумент `--insecure`, який дозволяє ArgoCD працювати без TLS всередині кластера, оскільки TLS термінація відбувається на NLB. */
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
