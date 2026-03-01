/* Встановлюємо EBS (Elastic Block Store) CSI Driver для забезпечення підтримки динамічного створення томів EBS в нашому кластері EKS. */

/* Використовуємо модуль `ebs-csi-driver` від DrFaust92, який спрощує процес встановлення EBS CSI Driver в Kubernetes.
- `source`: Вказує на джерело модуля, який ми використовуємо для встановлення EBS CSI Driver.
- `version`: Вказує версію модуля, яку ми хочемо використовати.
- `ebs_csi_controller_role_name`: Ім'я IAM ролі для контролера EBS CSI Driver.
- `ebs_csi_controller_role_policy_name_prefix`: Префікс для іменування політики IAM, яка буде прикріплена до ролі контролера EBS CSI Driver.
- `oidc_url`: URL OIDC провайдера, який використовується для налаштування IAM ролі для контролера EBS CSI Driver. Ми отримуємо це значення з ресурсу `aws_eks_cluster.danit`.
- `enable_volume_resizing`: Вказує, чи дозволити можливість зміни розміру томів EBS, створених через CSI Driver. У цьому випадку ми встановлюємо це значення в true, щоб дозволити зміну розміру томів. */
module "ebs-csi-driver" {
  source  = "DrFaust92/ebs-csi-driver/kubernetes"
  version = "3.10.0"

  ebs_csi_controller_role_name               = "ebs-csi-${var.name}-controller"
  ebs_csi_controller_role_policy_name_prefix = "ebs-csi-${var.name}-policy"
  oidc_url                                   = aws_eks_cluster.danit.identity[0].oidc[0].issuer
  enable_volume_resizing                     = true
}
