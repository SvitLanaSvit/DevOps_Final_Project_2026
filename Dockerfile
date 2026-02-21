FROM python:3.12-slim 

WORKDIR /app

COPY py_project/server.py .

# Оголошує порт 8000 як той, на якому додаток слухає всередині контейнера
ENV PORT=8000
EXPOSE 8000

CMD ["python", "server.py"]