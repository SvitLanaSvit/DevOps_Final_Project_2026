/*
  Цей файл визначає ресурс AWS Certificate Manager (ACM) для отримання SSL-сертифіката, 
  який буде використовуватися для захисту домену, пов'язаного з кластером EKS. 
  Сертифікат буде валідований через DNS, використовуючи запис у Route 53.
*/

/* Отримуємо інформацію про зону Route 53, яка відповідає вказаному імені зони. 
Використовуємо модуль ACM для створення сертифіката з основним доменом та альтернативними іменами. 
Сертифікат буде чекати на валідацію перед тим, як стати активним. */
data "aws_route53_zone" "zone" {
  name         = var.zone_name
  private_zone = false
}

/* Локальна змінна для формування повного доменного імені, 
яке буде використовуватися для сертифіката. */
locals {
  domain_name = "${var.name}.${var.zone_name}"
}

/* Використовуємо модуль ACM для створення сертифіката.
- `domain_name`: Основне доменне ім'я для сертифіката.
- `zone_id`: Ідентифікатор зони Route 53 для валідації сертифіката.
- `subject_alternative_names`: Додаткові доменні імена, які також будуть захищені сертифікатом (у цьому випадку всі піддомени).
- `wait_for_validation`: Чекаємо, поки сертифікат буде валідований, перш ніж він стане активним.
- `tags`: Додаємо теги для організації ресурсів. */
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.0"

  domain_name = local.domain_name
  zone_id     = data.aws_route53_zone.zone.zone_id

  subject_alternative_names = [
    "*.${local.domain_name}",
  ]

  wait_for_validation = true

  tags = merge(
    var.tags,
    { Name = "${var.name}-eks", Owner = "svitlana.kizilpinar@gmail.com" }
  )
}