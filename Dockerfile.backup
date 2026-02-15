# Build stage
FROM hexpm/elixir:1.17.3-erlang-27.1.2-alpine-3.20.3 AS build

# Install build dependencies (assets use Hex esbuild + Tailwind; no Node.js)
RUN apk add --no-cache \
    build-base \
    git \
    vips-dev \
    vips-heif

WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV=prod

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

# Copy compile-time config only (better cache when runtime.exs changes)
COPY config/config.exs config/prod.exs config/
RUN mix deps.compile

# Install Tailwind and esbuild executables
RUN mix assets.setup

# Copy source
COPY priv priv
COPY lib lib
RUN mix compile

# Copy assets and build
COPY assets assets
RUN mix assets.deploy

# Runtime config and release overlays (don't require recompile)
COPY config/runtime.exs config/
COPY rel rel
RUN mix release

# Runtime stage
FROM alpine:3.20.3

# Install runtime dependencies
RUN apk add --no-cache \
    openssl \
    ncurses-libs \
    vips \
    vips-heif \
    tar

WORKDIR /app

# Create non-root user
RUN adduser -D -h /app lumina
USER lumina

# Copy release from build stage
COPY --from=build --chown=lumina:lumina /app/_build/prod/rel/lumina ./

# Set environment
ENV HOME=/app
ENV MIX_ENV=prod
ENV PORT=4000

# Create data directories
RUN mkdir -p /app/data
RUN mkdir -p /app/priv/static/uploads/originals
RUN mkdir -p /app/priv/static/uploads/thumbnails

EXPOSE 4000

CMD ["bin/lumina", "start"]
