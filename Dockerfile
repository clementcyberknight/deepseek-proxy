# Builder stage
FROM python:3.11-slim AS builder

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uv/bin/uv

WORKDIR /app

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1
ENV PATH="/uv/bin:$PATH"

# Copy project files
COPY pyproject.toml uv.lock ./
COPY src/ ./src/

# Install dependencies
RUN uv sync --frozen --no-dev

# Final stage
FROM python:3.11-slim

WORKDIR /app

# Copy the environment from the builder
COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /app/src /app/src

# Set environment variables
ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONUNBUFFERED=1
ENV DEEPSEEK_PROXY_CONFIG_DIR=/data

# Expose the port (default is 9000)
EXPOSE 9000

# Ensure the data directory exists
RUN mkdir -p /data

# Run the app
CMD ["deepseek-cursor-proxy", "--host", "0.0.0.0", "--port", "9000", "--no-ngrok", "--config", "/data/config.yaml"]
