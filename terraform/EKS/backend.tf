/* Цей файл відповідає за налаштування бекенду для зберігання стану Terraform. Ми використовуємо S3 бакет для зберігання стану та DynamoDB для блокування, щоб уникнути конфліктів при одночасному виконанні Terraform. */

/* Блок `terraform` визначає налаштування бекенду для Terraform:
- `backend "s3"`: Вказує, що ми використовуємо S3 для зберігання стану.
- `bucket`: Ім'я S3 бакету, де буде зберігатися стан.
- `key`: Шлях до файлу стану в бакеті.  
- `encrypt`: Вказує, що стан повинен бути зашифрований в S3.
- `dynamodb_table`: Ім'я таблиці DynamoDB, яка використовується для блокування стану.
- `region`: Регіон AWS, де знаходяться S3 бакет та DynamoDB таблиця. */
terraform {
  backend "s3" {
    bucket         = "terraform-state-svitlana-vpc"
    key            = "eks/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "lock-tf-eks"
    # dynamo key LockID
    # Params tekan from -backend-config when terraform init
    region         = "eu-central-1"
    #profile = 
  }
}


