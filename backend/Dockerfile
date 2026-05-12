FROM python:3.12-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY config.py .
COPY .env .
COPY backend/ ./backend/

EXPOSE 5000

ENV FLASK_APP=backend/app.py
ENV FLASK_ENV=production

CMD ["python", "backend/app.py"]
