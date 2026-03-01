/* Цей файл відповідає за встановлення зовнішнього DNS (External DNS) в нашому EKS кластері. External DNS автоматично оновлює записи DNS у вашому домені, коли сервіси Kubernetes створюють або видаляють ресурси, які потребують DNS записів. Це дуже корисно для автоматизації управління DNS при розгортанні додатків в Kubernetes. */

/* Використовуємо модуль `lablabs/eks-external-dns/aws`, який спрощує процес встановлення External DNS в EKS кластері.
- `source`: Вказує на джерело модуля, який ми використовуємо для встановлення External DNS.
- `version`: Вказує версію модуля, яку ми хочемо використовувати.
- `cluster_identity_oidc_issuer`: URL OIDC провайдера, який використовується для налаштування IAM ролі для External DNS. Ми отримуємо це значення з ресурсу `aws_eks_cluster.danit`.
- `cluster_identity_oidc_issuer_arn`: ARN OIDC провайдера, який використовується для налаштування IAM ролі для External DNS. Ми отримуємо це значення з модуля `oidc-provider-data`.
- `irsa_role_name_prefix`: Префікс для іменування IAM ролі, яка буде використовуватися External DNS для доступу до Route53. Це дозволяє External DNS створювати та оновлювати DNS записи в Route53 без необхідності зберігати AWS ключі в кластері. */
module "eks-external-dns" {
  source                           = "lablabs/eks-external-dns/aws"
  version                          = "2.1.1"
  cluster_identity_oidc_issuer     = aws_eks_cluster.danit.identity.0.oidc.0.issuer
  cluster_identity_oidc_issuer_arn = module.oidc-provider-data.arn
  irsa_role_name_prefix            = var.name
}

