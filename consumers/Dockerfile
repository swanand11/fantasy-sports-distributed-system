FROM python:3.12-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend for db.py and config.py
COPY config.py .
COPY .env .
COPY backend/ ./backend/

# Copy consumer scripts
COPY consumers/ ./consumers/

# Entrypoint will be overridden in k8s manifests to specify which consumer to run
CMD ["echo", "Please specify a consumer script to run"]
