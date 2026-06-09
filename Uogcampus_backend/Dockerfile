FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

WORKDIR /app

# Install system dependencies for Postgres and AI
RUN apt-get update && apt-get install -y libpq-dev gcc

COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

COPY . /app/

# ✅ CRITICAL: Hugging Face uses Port 7860
CMD ["gunicorn", "core.wsgi:application", "--bind", "0.0.0.0:7860"]