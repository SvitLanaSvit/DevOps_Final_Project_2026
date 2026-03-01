/* Файл `provider.tf` налаштовує провайдери для роботи з AWS та Kubernetes. Він визначає, як Terraform буде взаємодіяти з AWS для створення ресурсів EKS та з Kubernetes для управління кластером. */

/* Провайдер `aws` використовується для взаємодії з AWS API. Він налаштований на використання регіону та профілю, які визначені в змінних `var.region` та `var.iam_profile`. Це дозволяє Terraform створювати ресурси в правильному регіоні та використовувати правильні облікові дані для аутентифікації. */
provider "aws" {
  region  = var.region
  profile = var.iam_profile
}

 /* Провайдер `kubernetes` використовується для взаємодії з Kubernetes API. Він налаштований на використання даних з EKS кластера, таких як endpoint, сертифікат та токен аутентифікації. Це дозволяє Terraform керувати ресурсами всередині кластера. */
provider "kubernetes" {
  host                   = aws_eks_cluster.danit.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.danit.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.danit.token
}

/* Terraform блок для визначення необхідних провайдерів та їх версій. Тут ми вказуємо, що нам потрібен провайдер `helm` для управління Helm чартами в Kubernetes, і визначаємо його версію. */
terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "= 2.12.1"
    }
  }
}

/* Провайдер `helm` для управління Helm чартами в Kubernetes. Він налаштований на використання даних з EKS кластера, таких як endpoint, сертифікат та токен аутентифікації. Це дозволяє Terraform встановлювати та керувати Helm чартами всередині кластера. */
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.danit.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.danit.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.danit.token

  }
}

/* Ресурс `aws_iam_openid_connect_provider` для створення OIDC провайдера, який використовується для налаштування IAM ролей для сервісів, які працюють всередині EKS кластера. Це дозволяє нам використовувати IRSA (IAM Roles for Service Accounts) для надання конкретних прав доступу сервісам в Kubernetes без необхідності зберігати AWS ключі в контейнері. */
data "aws_availability_zones" "available" {}

