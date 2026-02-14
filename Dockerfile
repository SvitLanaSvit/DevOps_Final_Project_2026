FROM python:3.12-slim 

WORKDIR /app

COPY py_project/server.py .

ENV PORT=8000
EXPOSE 8000

CMD ["python", "server.py"]