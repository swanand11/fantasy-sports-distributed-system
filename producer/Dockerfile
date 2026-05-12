FROM python:3.12-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy producer scripts
COPY producer/ ./producer/

# Entrypoint will be overridden depending on which producer to run
CMD ["echo", "Please specify a producer script to run (e.g., python producer/match.py)"]
