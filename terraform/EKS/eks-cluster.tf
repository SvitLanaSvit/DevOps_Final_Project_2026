/* Цей файл відповідає за створення самого EKS кластера, який є основою для всього нашого Kubernetes середовища. Тут ми визначаємо конфігурацію кластера, включаючи мережеві налаштування та ролі доступу. */

/* Ресурс `aws_eks_cluster` для створення EKS кластера:
- `name`: Ім'я кластера.
- `role_arn`: ARN ролі IAM для кластера.
- `vpc_config`: Конфігурація VPC, включаючи security group та підмережі.
- `depends_on`: Залежності від інших ресурсів.
- `tags`: Теги для кластера.
*/
resource "aws_eks_cluster" "danit" {
  name     = var.name
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    security_group_ids = [aws_security_group.danit-cluster.id]
    subnet_ids         = var.subnets_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.kubeedge-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.kubeedge-cluster-AmazonEKSVPCResourceController,
  ]
  tags = merge(
    var.tags,
    { Name = "${var.name}", Owner = "svitlana.kizilpinar@gmail.com" }
  )
}


/* Ресурс `aws_eks_cluster_auth` для отримання інформації про аутентифікацію до EKS кластера. Це необхідно для налаштування kubectl та інших інструментів, які будуть взаємодіяти з кластером. */
data "aws_eks_cluster_auth" "danit" {
  name = aws_eks_cluster.danit.name
}

/* Ресурс `aws_eks_addon` для встановлення CoreDNS як аддона в EKS кластері. CoreDNS є основним DNS сервером для Kubernetes, який забезпечує розв'язання імен всередині кластера. */
resource "aws_eks_addon" "coredns" {
  cluster_name                = var.name
  addon_name                  = "coredns"
  addon_version               = "v1.12.4-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [aws_eks_node_group.danit]
}
