# Multi-Stage Production Dockerfile for HER AREA Django REST API Engine
FROM python:3.12-slim as builder

WORKDIR /build

# Install compilation prerequisites
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Final minimal production image
FROM python:3.12-slim

WORKDIR /app

# Install runtime PostgreSQL libraries & security utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy installed python dependencies from builder stage
COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV DJANGO_DEBUG=False

# Copy backend source codebase
COPY . /app/

# Collect static assets and prepare directories
RUN mkdir -p logs staticfiles mediafiles \
    && useradd -m -u 1000 herarea_user \
    && chown -R herarea_user:herarea_user /app

USER herarea_user

EXPOSE 8000

# Launch high-performance WSGI deployment via Gunicorn
CMD ["gunicorn", "config.wsgi:application", "-c", "gunicorn.conf.py"]
