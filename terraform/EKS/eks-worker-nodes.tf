/* Цей файл відповідає за створення групи робочих вузлів (worker nodes) для нашого EKS кластера. Робочі вузли - це EC2 інстанси, які виконують контейнеризовані додатки в Kubernetes. Тут ми визначаємо конфігурацію для цих вузлів, включаючи тип інстансу, кількість вузлів та ролі доступу. */

/* Ресурс `aws_eks_node_group` для створення групи робочих вузлів:
- `cluster_name`: Ім'я EKS кластера, до якого буде приєднана ця група вузлів.
- `node_group_name`: Ім'я групи вузлів. 
- `node_role_arn`: ARN ролі IAM, яка буде призначена вузлам.
- `subnet_ids`: Список підмереж, в яких будуть створені вузли.
- `scaling_config`: Конфігурація масштабування, яка визначає бажану кількість вузлів, а також мінімальну та максимальну кількість вузлів у групі.
- `instance_types`: Типи EC2 інстансів, які будуть використовуватися для вузлів. У цьому випадку ми використовуємо `t3.medium`, який є збалансованим варіантом для тестових середовищ.
- `labels`: Набір міток, які будуть застосовані до вузлів. Це може бути корисно для організації та вибору вузлів за допомогою селекторів в Kubernetes.
- `depends_on`: Залежності від інших ресурсів, які повинні бути створені перед створенням цієї групи вузлів. У цьому випадку ми залежимо від прикріплення політик IAM до ролі вузлів, щоб забезпечити необхідні дозволи для роботи в EKS.
- `tags`: Теги для групи вузлів, які допомагають у організації та управлінні ресурсами в AWS. Ми використовуємо функцію `merge` для об'єднання загальних тегів з додатковим тегом, який вказує на ім'я групи вузлів. */ 
resource "aws_eks_node_group" "danit" {
  cluster_name    = aws_eks_cluster.danit.name
  node_group_name = var.name
  node_role_arn   = aws_iam_role.danit-node.arn
  subnet_ids      = var.subnets_ids

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  labels = {
    "node-type" : "tests"
  }

  depends_on = [
    aws_iam_role_policy_attachment.kubeedge-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.kubeedge-node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.kubeedge-node-AmazonEC2ContainerRegistryReadOnly,
  ]
  tags = merge(
    var.tags,
    { Name = "${var.name}-node-group", Owner = "svitlana.kizilpinar@gmail.com" }
  )
}


