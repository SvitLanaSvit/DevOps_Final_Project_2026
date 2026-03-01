/* Файл `sg.tf` відповідає за створення та налаштування Security Group для EKS кластера. Він визначає правила доступу до кластеру, зокрема дозволяє зовнішньому робочому місцю (workstation) підключатися до API сервера кластера через HTTPS. Це важливо для безпечного управління кластером та забезпечення зв’язку між робочим місцем та кластером. */

/* Ресурс `aws_security_group` створює Security Group для EKS кластера. Він визначає ім’я, опис та VPC, до якого належить Security Group. Також він налаштовує правила вихідного трафіку (egress), дозволяючи весь вихідний трафік. Теги допомагають у організації ресурсів в AWS. */
resource "aws_security_group" "danit-cluster" {
  name        = "${var.name}-eks-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    { Name = "${var.name}-eks-sg" }
  )
}

/* Ресурс `aws_security_group_rule` для дозволу підключення до API сервера EKS кластера з зовнішнього робочого місця (workstation) через HTTPS. Він використовує CIDR блок, який відповідає зовнішній IP адресі робочого місця, обмежуючи доступ лише до цього IP. Це забезпечує безпеку, дозволяючи підключатися до кластеру лише з відомого джерела. */
data "http" "workstation-external-ip" {
  url = "http://ipv4.icanhazip.com"
}

# Override with variable or hardcoded value if necessary
/* Локальна змінна `workstation-external-cidr` формує CIDR блок з зовнішньої IP адреси робочого місця, додаючи суфікс `/32`, що означає, що дозволений лише цей конкретний IP. Це використовується в правилі безпеки для обмеження доступу до API сервера EKS кластера. */
locals {
  workstation-external-cidr = "${chomp(data.http.workstation-external-ip.response_body)}/32"
}

/* Ресурс `aws_security_group_rule` для дозволу підключення до API сервера EKS кластера з зовнішнього робочого місця (workstation) через HTTPS. Він використовує CIDR блок, який відповідає зовнішній IP адресі робочого місця, обмежуючи доступ лише до цього IP. Це забезпечує безпеку, дозволяючи підключатися до кластеру лише з відомого джерела. */
resource "aws_security_group_rule" "kubeedge-cluster-ingress-workstation-https" {
  cidr_blocks       = [local.workstation-external-cidr]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.danit-cluster.id
  to_port           = 443
  type              = "ingress"
}

