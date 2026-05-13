# 1. Builder stage
FROM python:3.11-slim AS builder

# Install uv binary
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set configuration for uv
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy

WORKDIR /app

# Install dependencies only (for better layer caching)
RUN --mount=type=cache,id=uv,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev

# Copy source code
COPY src/ ./src/
COPY pyproject.toml uv.lock ./

# Install the project itself
RUN --mount=type=cache,id=uv,target=/root/.cache/uv \
    uv sync --frozen --no-dev

# 2. Final runtime stage
FROM python:3.11-slim AS runtime

WORKDIR /app

# Copy the virtual environment and source code
COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /app/src /app/src

# Ensure the virtual environment is in the PATH
ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONUNBUFFERED=1
ENV DEEPSEEK_PROXY_CONFIG_DIR=/data

# Expose the default port
EXPOSE 9000

# Create data directory
RUN mkdir -p /data

# Run the application
# We use the entrypoint defined in pyproject.toml
# Use string form to allow environment variable expansion
CMD deepseek-cursor-proxy --host 0.0.0.0 --port ${PORT:-9000} --no-ngrok --config /data/config.yaml

