# DevOps Final Project 2026 – Python Backend on EKS with ArgoCD (GitOps)

Цей репозиторій — фінальний DevOps‑проєкт. Він показує повний шлях від простого Python backend‑сервера до продакшн‑подібного деплою в AWS EKS з GitOps‑керуванням через ArgoCD.

Основна ідея:

- код backend'а → Docker‑образ у Docker Hub (GitHub Actions);
- інфраструктура в AWS (EKS, ingress, external-dns, ACM) описана Terraform'ом;
- застосунок у Kubernetes описаний «чистими» YAML‑маніфестами;
- ArgoCD синхронізує стан кластера з Git і автоматично оновлює застосунок при змінах у репозиторії.

---

## Архітектура

Коротко:

- **AWS EKS** кластер у `eu-central-1` з однією node group;
- **nginx Ingress Controller** (Service type `LoadBalancer`) + AWS NLB;
- **external-dns** для автоматичної реєстрації DNS‑записів у Route53 в зоні `devops10.test-danit.com`;
- **ACM** TLS‑сертифікат для `*.sk.devops10.test-danit.com`;
- **ArgoCD** в namespace `argocd`, доступний за HTTPS: `https://argocd.sk.devops10.test-danit.com`;
- **Python backend** у namespace `app`, доступний за HTTPS: `https://app.sk.devops10.test-danit.com`;
- ArgoCD Application `app-sk` керує маніфестами в каталозі `k8s/app`.

Діаграма архітектури: див. [docs/_architecture-diagrams.md](docs/_architecture-diagrams.md).

---

## Структура репозиторію

- **py_project/** – вихідний код Python backend'а
  - `server.py` – HTTP‑сервер, що слухає порт 8000 і на `/` повертає `OK from pod IP: <ip>`.
- **Dockerfile** – збірка образу `svitlanakizilpinar/final-app`.
- **.github/workflows/docker-image.yml** – GitHub Actions workflow, який збирає Docker‑образ і пушить його в Docker Hub з тегами:
  - `latest`;
  - `${{ github.sha }}` (повний SHA коміту).
- **terraform/EKS/** – код Terraform для всієї інфраструктури в AWS:
  - `provider.tf`, `variables.tf`, `terraform.tfvars`, `backend.tf` – базові налаштування;
  - `eks-cluster.tf`, `eks-worker-nodes.tf`, `sg.tf`, `iam.tf` – EKS кластер, node group, security groups, IAM ролі;
  - `ingress_controller.tf` – nginx Ingress Controller;
  - `eks-external-dns.tf` – external-dns для Route53;
  - `acm.tf` – ACM сертифікат для `*.sk.devops10.test-danit.com`;
  - `argocd.tf` – встановлення ArgoCD в кластері.
- **k8s/app/** – Kubernetes‑маніфести застосунку:
  - `namespace.yaml` – namespace `app`;
  - `deployment.yaml` – Deployment `backend` (образ з Docker Hub, порт 8000, RollingUpdate);
  - `service.yaml` – `backend-svc` (ClusterIP, порт 80 → 8000);
  - `ingress.yaml` – `backend-ingress` з host `app.sk.devops10.test-danit.com`.
- **docs/** – покрокова документація (українською):
  - `1_aws-mfa-login.md` – вхід до AWS з MFA;
  - `2_python-backend-server.md` – Python backend;
  - `3_dockerfile-backend-image.md` – Dockerfile + локальні тести образу;
  - `4_github-actions-docker-ci.md` – GitHub Actions для збірки/публікації образу;
  - `5_terraform-eks-cluster.md` – створення EKS, nginx ingress, external-dns, ACM;
  - `6_terraform-argocd-eks.md` – встановлення ArgoCD і видача домену `argocd.sk.devops10.test-danit.com`;
  - `7_k8s-app-manifests.md` – ручний деплой backend'а в EKS через `kubectl`;
  - `8_argocd-app-autosync.md` – налаштування ArgoCD Application `app-sk` та AUTO-SYNC.
- **screens/** – усі скріншоти для документації.
- **task.txt** – повний текст завдання (укр/англ).

---

## Як відтворити інфраструктуру

> Передумови: встановлені `awscli`, `kubectl`, `terraform`, доступ до AWS з MFA, WSL/Ubuntu на Windows (або Linux/macOS).

1. **Логін в AWS з MFA**  
   Детально: [docs/1_aws-mfa-login.md](docs/1_aws-mfa-login.md).

2. **Створити/оновити EKS кластер**

   ```bash
   cd terraform/EKS
   terraform init
   terraform plan
   terraform apply
   ```

   Це створить: VPC‑ресурси, EKS кластер, node group, nginx ingress controller, external-dns, ACM сертифікат і ArgoCD.

3. **Оновити kubeconfig і перевірити кластер**

   ```bash
   aws eks update-kubeconfig --region eu-central-1 --name sk
   kubectl cluster-info
   kubectl get nodes
   kubectl get pods -A
   ```

4. **Перевірити, що ArgoCD доступний за HTTPS**  
   Деталі налаштування DNS і TLS: [docs/6_terraform-argocd-eks.md](docs/6_terraform-argocd-eks.md).

---

## CI: збірка та публікація Docker‑образу

1. Налаштувати секрети GitHub:

   - `DOCKERHUB_USERNAME` – логін Docker Hub;
   - `DOCKERHUB_TOKEN` – access token Docker Hub.

2. При кожному пуші в `main` workflow [.github/workflows/docker-image.yml](.github/workflows/docker-image.yml) виконує:

   - `docker build` образу на основі `Dockerfile`;
   - пуш в Docker Hub як `svitlanakizilpinar/final-app:latest` і `svitlanakizilpinar/final-app:<github_sha>`.

---

## GitOps: ArgoCD + Kubernetes маніфести

1. **Маніфести застосунку** лежать у [k8s/app](k8s/app):

   - `deployment.yaml` посилається на образ з Docker Hub (тег = SHA коміту);
   - `service.yaml` і `ingress.yaml` описують доступ до застосунку всередині кластера та з Інтернету.

2. **ArgoCD Application `app-sk`**:

   - **Repository URL**: цей GitHub‑репозиторій;
   - **Revision**: `main`;
   - **Path**: `k8s/app`;
   - **Destination**: `https://kubernetes.default.svc`, namespace `app` (з опцією `AUTO-CREATE NAMESPACE`);
   - **Sync Policy**: AUTO-SYNC увімкнена (за бажанням: PRUNE, SELF-HEAL).

   Детальний покроковий опис з усіма скрінами: [docs/8_argocd-app-autosync.md](docs/8_argocd-app-autosync.md).

3. **Флоу оновлення версії**:

   - новий коміт у `main` → GitHub Actions збирає новий образ з тегом SHA;
   - у `k8s/app/deployment.yaml` змінюється рядок `image: svitlanakizilpinar/final-app:<SHA>`;
   - коміт з оновленим маніфестом пушиться в `main`;
   - ArgoCD бачить різницю, автоматично синхронізує застосунок і запускає rolling update в EKS;
   - новий pod відповідає на `https://app.sk.devops10.test-danit.com` рядком `OK from pod IP: ...`.

---

## Як перевірити, що все працює

1. **Кластер і поди**:

   ```bash
   kubectl get ns
   kubectl get pods -n app -o wide
   kubectl get svc -n app
   kubectl get ingress -n app
   ```

2. **Перевірка образу в Deployment**:

   ```bash
   kubectl describe deployment backend -n app | grep -i image
   ```

3. **DNS та доступ з Інтернету**:

   ```bash
   nslookup argocd.sk.devops10.test-danit.com 8.8.8.8
   nslookup app.sk.devops10.test-danit.com 8.8.8.8
   ```

   Після оновлення DNS (через external-dns) в браузері:

   - `https://argocd.sk.devops10.test-danit.com` – UI ArgoCD;
   - `https://app.sk.devops10.test-danit.com` – відповідь backend'а `OK from pod IP: <ip>`.

> Примітка: іноді локальний DNS/браузер кешують старий NXDOMAIN. У такому випадку допомагає `ipconfig /flushdns` на Windows і повний перезапуск браузера.

---

## Де шукати деталі

Якщо потрібні глибші пояснення по кожному кроку (MFA, Terraform, CI, ArgoCD, k8s‑маніфести) — усі вони документовані в каталозі [docs](docs) з великою кількістю скріншотів.
