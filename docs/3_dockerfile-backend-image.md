# Dockerfile для Python backend

## Призначення

Цей Dockerfile збирає Docker‑образ для нашого простого Python backend‑сервера (`py_project/server.py`). Надалі цей образ буде:
- пушитись у Docker Hub через CI (GitHub Actions);
- використовуватись у Kubernetes Deployment в EKS;
- оновлюватись автоматично через ArgoCD.

## Локація файлу

Dockerfile знаходиться в корені репозиторію:
- `Dockerfile`

## Пояснення інструкцій Dockerfile

Актуальний вміст (логіка, не обов’язково дослівний текст):

1. **Базовий образ**
   ```Dockerfile
   FROM python:3.12-slim
   ```
   - Використовується офіційний базовий образ Python версії 3.12 у варіанті `slim` (мінімальний Debian‑образ).
   - Містить все необхідне для запуску Python‑скриптів, але без зайвих пакетів.

2. **Робоча директорія всередині контейнера**
   ```Dockerfile
   WORKDIR /app
   ```
   - Встановлює `/app` як поточний каталог для всіх наступних команд (`COPY`, `CMD` тощо).

3. **Копіювання коду застосунку**
   ```Dockerfile
   COPY py_project/server.py .
   ```
   - Копіює файл `py_project/server.py` з репозиторію в робочу директорію контейнера (`/app/server.py`).
   - Інших залежностей у застосунку немає, тому додаткових `pip install` не потрібно.

4. **Налаштування порту**
   ```Dockerfile
   ENV PORT=8000
   EXPOSE 8000
   ```
   - `ENV PORT=8000` задає змінну середовища `PORT`, яку читає `server.py` (якщо змінна не задана, використовується 8000 за замовчуванням).
   - `EXPOSE 8000` документує, що контейнер слухає порт 8000. Це не відкриває порт зовні, але використовується інструментами (docker run, docker-compose, Kubernetes).

5. **Команда запуску контейнера**
   ```Dockerfile
   CMD ["python", "server.py"]
   ```
   - Вказує, що при старті контейнера Docker повинен запустити команду `python server.py` у робочій директорії `/app`.
   - У результаті піднімається HTTP‑сервер, який слухає `0.0.0.0:PORT` і віддає відповідь `OK from pod IP: ...` на запит `GET /`.

## Локальна збірка та запуск образу

### Збірка образу

У корені проєкту (там, де лежить Dockerfile):

```bash
cd /d/DevOps/Final_Project_2026

docker build -t svitlanakizilpinar/final-app:local .
```

- `-t svitlanakizilpinar/final-app:local` — тег образу, де `svitlanakizilpinar` — Docker Hub username, `final-app` — назва репозиторію образу, `local` — тег.

### Запуск контейнера

```bash
docker run --rm -p 8000:8000 svitlanakizilpinar/final-app:local
```

- `-p 8000:8000` — проброс порту: локальний 8000 → порт 8000 у контейнері.
- `--rm` — автоматично видалити контейнер після зупинки.

Перевірка:

```bash
curl http://localhost:8000/
```

У відповідь очікується рядок на кшталт:

```text
OK from pod IP: 172.x.x.x
```

Це підтверджує, що образ зібрано коректно, Dockerfile працює, і контейнер слухає потрібний порт.
