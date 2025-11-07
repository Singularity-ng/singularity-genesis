# Dockerfile for Singularity Workflow
# Multi-stage build for optimized production image

# Stage 1: Build
FROM elixir:1.19-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    npm \
    postgresql-client

# Set working directory
WORKDIR /app

# Set build environment
ENV MIX_ENV=prod

# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy dependency files
COPY mix.exs mix.lock ./

# Install and compile dependencies
RUN mix deps.get --only prod && \
    mix deps.compile

# Copy application code
COPY config config
COPY lib lib
COPY priv priv

# Compile application
RUN mix compile

# Stage 2: Release
FROM elixir:1.19-alpine AS releaser

WORKDIR /app

ENV MIX_ENV=prod

RUN mix local.hex --force && \
    mix local.rebar --force

# Copy compiled application from builder
COPY --from=builder /app/_build /app/_build
COPY --from=builder /app/deps /app/deps
COPY --from=builder /app/config /app/config
COPY --from=builder /app/lib /app/lib
COPY --from=builder /app/priv /app/priv
COPY --from=builder /app/mix.exs /app/mix.lock ./

# Create release
RUN mix release

# Stage 3: Runtime
FROM alpine:3.19 AS runtime

# Install runtime dependencies
RUN apk add --no-cache \
    libstdc++ \
    openssl \
    ncurses-libs \
    postgresql-client \
    bash

# Create non-root user
RUN addgroup -g 1000 singularity && \
    adduser -D -u 1000 -G singularity singularity

WORKDIR /app

# Copy release from releaser stage
COPY --from=releaser --chown=singularity:singularity /app/_build/prod/rel/singularity_workflow ./

# Switch to non-root user
USER singularity

# Expose port (if needed for health checks or API)
EXPOSE 4000

# Set environment
ENV HOME=/app
ENV MIX_ENV=prod
ENV LANG=C.UTF-8

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD ["/app/bin/singularity_workflow", "rpc", "1 + 1"]

# Start the application
CMD ["/app/bin/singularity_workflow", "start"]
