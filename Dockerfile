FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

ENV LICENSE_DB_SEED=true \
    LICENSE_DB_PATH=/data/licenses.db \
    HOST=0.0.0.0 \
    PORT=8000 \
    APP_VERSION=dev

RUN mkdir -p /data

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]


