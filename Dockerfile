FROM ghcr.io/astral-sh/uv:python3.11-slim AS builder

WORKDIR /app

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

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
# Use --host 0.0.0.0 to allow external connections in Docker
# Use --no-ngrok because Coolify provides its own ingress/reverse proxy
# We use --config to point to a persistent location
CMD ["deepseek-cursor-proxy", "--host", "0.0.0.0", "--port", "9000", "--no-ngrok", "--config", "/data/config.yaml"]
