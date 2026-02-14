# AWS MFA логін для фінального проєкту

## 1. Одноразове налаштування профілю без MFA

1. Отримай `Access key ID` та `Secret access key` для свого IAM користувача (CSV з консолі AWS).
2. В терміналі Git Bash виконай:
   ```bash
   aws configure --profile danit-without-mfa
   ```
3. Введи значення:
   - `AWS Access Key ID` – з CSV
   - `AWS Secret Access Key` – з CSV
   - `Default region name` – наприклад `eu-central-1`
   - `Default output format` – можна залишити порожнім або `json`.

Цей крок робиться **один раз**, поки ключ дійсний.

## 2. Отримання тимчасових MFA‑креденшіалів перед роботою

Кожен раз, коли починаєш роботу з AWS (або коли сесія протухла):

1. Перейди в корінь проєкту:
   ```bash
   cd /d/DevOps/Final_Project_2026
   ```
2. Запусти скрипт MFA:
   ```bash
   ./mfa/dan-it-aws-login.sh
   ```
3. Введи 6‑значний код із додатку MFA (Google Authenticator тощо).
4. При успіху побачиш повідомлення:
   ```
   Temporary credentials saved under profile 'default'.
   ```

Скрипт бере довгострокові ключі з профілю `danit-without-mfa`, викликає `sts get-session-token` і записує тимчасові креденшіали в профіль `default`. Після цього всі команди `aws ...` та `terraform ...` працюють через MFA‑сесію.

## 3. Перевірка, що все працює

Після запуску скрипта перевір:

```bash
aws sts get-caller-identity
aws eks list-clusters
```

Якщо повертається інформація про користувача і немає помилки `UnauthorizedOperation`, значить MFA‑сесія налаштована коректно.