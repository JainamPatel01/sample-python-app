# Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install runtime deps
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy app
COPY . .

# Expose configurable port
ENV APP_PORT=5000
EXPOSE ${APP_PORT}

ENTRYPOINT ["python3", "/app/src/app.py"]
