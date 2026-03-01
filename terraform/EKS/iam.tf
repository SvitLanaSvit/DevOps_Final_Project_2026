/* Цей файл відповідає за налаштування IAM ролей та політик для EKS кластера та його робочих вузлів. IAM ролі визначають, які дії можуть виконувати різні компоненти кластера, такі як сам кластер, робочі вузли та зовнішні сервіси, які взаємодіють з кластером. */

/* Ресурс `aws_iam_role` для створення ролі IAM для EKS кластера. Ця роль дозволяє EKS виконувати необхідні дії для управління кластером, такі як створення ресурсів, управління мережевими налаштуваннями та взаємодія з іншими сервісами AWS. */
resource "aws_iam_role" "cluster" {
  name = "${var.name}-eks-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
  tags = merge(
    var.tags,
    { Name = "${var.name}-eks-role", Owner = "svitlana.kizilpinar@gmail.com" }
  )
}

/* Ресурси `aws_iam_role_policy_attachment` для прикріплення необхідних політик до ролі кластера. Ці політики надають EKS необхідні дозволи для управління кластером та його ресурсами. */
resource "aws_iam_role_policy_attachment" "kubeedge-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

/* Ресурс `aws_iam_role_policy_attachment` для прикріплення політики AmazonEKSVPCResourceController до ролі кластера. Ця політика дозволяє EKS керувати ресурсами VPC, такими як ENI (Elastic Network Interfaces), які використовуються для підключення робочих вузлів до кластеру. */
resource "aws_iam_role_policy_attachment" "kubeedge-cluster-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

/* Дата 'tls_certificate' для отримання інформації про TLS сертифікат OIDC провайдера, який використовується для налаштування IAM ролей для сервісів, які працюють всередині EKS кластера. Це необхідно для створення OIDC провайдера з правильними thumbprint-ами, що забезпечує безпечну аутентифікацію. */
data "tls_certificate" "cert" {
  url = aws_eks_cluster.danit.identity[0].oidc[0].issuer
}

/* Ресурс `aws_iam_openid_connect_provider` для створення OIDC провайдера, який використовується для налаштування IAM ролей для сервісів, які працюють всередині EKS кластера. Це дозволяє нам використовувати IRSA (IAM Roles for Service Accounts) для надання дозволів сервісам Kubernetes без необхідності зберігати AWS ключі в кластері. */
resource "aws_iam_openid_connect_provider" "openid_connect" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cert.certificates.0.sha1_fingerprint]
  url             = aws_eks_cluster.danit.identity[0].oidc[0].issuer
}

/* Модуль `oidc-provider-data` для отримання додаткової інформації про OIDC провайдера, який ми створили. Це дозволяє нам отримати ARN OIDC провайдера, який використовується для налаштування IAM ролей для сервісів, які працюють всередині EKS кластера. */
module "oidc-provider-data" {
  source     = "reegnz/oidc-provider-data/aws"
  version    = "0.0.3"
  issuer_url = aws_eks_cluster.danit.identity[0].oidc[0].issuer
}

/* Ресурс `aws_iam_role` для створення ролі IAM для робочих вузлів EKS. Ця роль дозволяє EC2 інстансам, які виконують робочі вузли, взаємодіяти з EKS та іншими сервісами AWS, необхідними для роботи Kubernetes. */
resource "aws_iam_role" "danit-node" {
  name = "${var.name}-eks-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
  tags = merge(
    var.tags,
    { Name = "${var.name}-eks-node-role" }
  )
}



#Як що помилка при створенні кластера про те що нема доступу до ListHostedZones й ListResourceRecordSets
#Значить ви не авторизувались з MFA

/* Ресурс `aws_iam_policy` для створення кастомної політики IAM, яка дозволяє читати секрети з AWS Secrets Manager. Ця політика буде прикріплена до ролі робочих вузлів, щоб вони могли отримувати доступ до секретів, необхідних для роботи додатків в Kubernetes. */
resource "aws_iam_policy" "secrets_policy" {
  name        = "${var.name}-GetSecrets"
  path        = "/"
  description = "Policy to read aws secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "AllowListHostedZones",
        "Effect" : "Allow",
        "Action" : [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
        ],
        "Resource" : "*"
      }
    ]
  })
}

/* Ресурси `aws_iam_role_policy_attachment` для прикріплення необхідних політик до ролі робочих вузлів. Ці політики надають робочим вузлам необхідні дозволи для взаємодії з EKS та іншими сервісами AWS, такими як Secrets Manager та Route53. */
resource "aws_iam_role_policy_attachment" "kubeedge-node-AmazonSecretsPolicy" {
  policy_arn = aws_iam_policy.secrets_policy.arn
  role       = aws_iam_role.danit-node.name
}

/* Ресурси `aws_iam_role_policy_attachment` для прикріплення стандартних політик AmazonEKSWorkerNodePolicy, AmazonEKS_CNI_Policy та AmazonEC2ContainerRegistryReadOnly до ролі робочих вузлів. Ці політики надають робочим вузлам необхідні дозволи для роботи в EKS, управління мережевими ресурсами та доступу до ECR (Elastic Container Registry) для отримання контейнерних образів. */
resource "aws_iam_role_policy_attachment" "kubeedge-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.danit-node.name
}

/* Ресурс `aws_iam_role_policy_attachment` для прикріплення політики AmazonEKS_CNI_Policy до ролі робочих вузлів. Ця політика дозволяє робочим вузлам керувати мережевими ресурсами, необхідними для роботи Kubernetes, такими як ENI (Elastic Network Interfaces) та IP адреси. */
resource "aws_iam_role_policy_attachment" "kubeedge-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.danit-node.name
}

/* Ресурс `aws_iam_role_policy_attachment` для прикріплення політики AmazonEC2ContainerRegistryReadOnly до ролі робочих вузлів. Ця політика дозволяє робочим вузлам отримувати доступ до ECR (Elastic Container Registry) для завантаження контейнерних образів, необхідних для роботи додатків в Kubernetes. */
resource "aws_iam_role_policy_attachment" "kubeedge-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.danit-node.name
}
