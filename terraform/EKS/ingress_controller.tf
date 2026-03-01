/* Використовуємо ресурс `helm_release` для встановлення Ingress Controller (nginx-ingress) в кластер EKS.
- `name`: Ім'я релізу Helm. 
- `repository`: URL репозиторію Helm, де знаходиться чарт для nginx-ingress.
- `chart`: Назва чарта для встановлення.
- `version`: Версія чарта, яку ми хочемо встановити.
- `namespace`: Kubernetes namespace, де буде встановлено Ingress Controller. У цьому випадку це `kube-system`.
- `create_namespace`: Якщо true, Terraform створить namespace, якщо він ще не існує.
- `set`: Використовуємо для налаштування параметрів чарта. У цьому випадку ми додаємо анотації до сервісу Ingress Controller, щоб він використовував ACM сертифікат для TLS, налаштовує протокол бекенду на HTTP, вказує, що балансувальник буде інтернет-орієнтованим і використовуватиме NLB, а також налаштовує порти для HTTP та HTTPS. */

resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.10.0"
  namespace        = "kube-system"
  create_namespace = true

  /* Додаємо анотацію для вказівки ACM сертифіката, який буде використовуватися для TLS термінації на NLB.
  - `service.beta.kubernetes.io/aws-load-balancer-ssl-cert`: Вказує ARN ACM сертифіката, який NLB використовуватиме для TLS термінації. Ми підставляємо значення `module.acm.acm_certificate_arn`, яке отримуємо з ресурсу ACM, визначеного в `acm.tf`. */
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"
    value = module.acm.acm_certificate_arn
  }

  /* Додаткові анотації для налаштування NLB:
  - `aws-load-balancer-backend-protocol`: Вказує, що протокол між NLB та бекендом (Ingress Controller) буде HTTP. */
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-backend-protocol"
    value = "http"
  }

  /** Додаткові анотації для налаштування NLB:
  - `aws-load-balancer-ssl-ports`: Вказує, які порти використовують SSL (у цьому випадку HTTPS).
  - `aws-load-balancer-scheme`: Вказує, що балансувальник буде інтернет-орієнтованим.
  - `aws-load-balancer-type`: Вказує, що тип балансувальника буде NLB. */
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-ports"
    value = "https"
  }

  /* Додаткові анотації для налаштування NLB:
  - `aws-load-balancer-scheme`: Вказує, що балансувальник буде інтернет-орієнтованим. */
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }

  /* Додаткові анотації для налаштування NLB:
  - `aws-load-balancer-type`: Вказує, що тип балансувальника буде NLB. */
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }

  /* Налаштовуємо порти для сервісу Ingress Controller:
  - `controller.service.targetPorts.http`: Вказує, що порт HTTP на сервісі Ingress Controller буде спрямовуватися на порт з назвою "http" в контейнері.
  - `controller.service.targetPorts.https`: Вказує, що порт HTTPS на сервісі Ingress Controller буде спрямовуватися на порт з назвою "http" в контейнері (оскільки TLS термінація відбувається на NLB, Ingress Controller все одно слухає HTTP). */
  set {
    name  = "controller.service.targetPorts.http"
    value = "http"
  }

  /* Налаштовуємо порт HTTPS для сервісу Ingress Controller, спрямовуючи його на той же порт "http" в контейнері, оскільки TLS термінація відбувається на NLB. */
  set {
    name  = "controller.service.targetPorts.https"
    value = "http"
  }
}
