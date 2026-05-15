FROM python:3.8-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    g++ \
    libgomp1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements_deploy.txt .

RUN pip install --upgrade pip setuptools wheel

RUN pip install --no-cache-dir --retries 10 --timeout 120 -r requirements_deploy.txt

COPY app ./app
COPY artifact ./artifact

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]