# Build stage
FROM hexpm/elixir:1.17.3-erlang-27.1.2-alpine-3.20.3 AS build

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    vips-dev \
    vips-heif \
    nodejs \
    npm

WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV=prod

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy source
COPY config config
COPY lib lib
COPY priv priv

# Copy assets
COPY assets assets

# Install npm dependencies and compile assets
RUN cd assets && npm install
RUN mix assets.deploy

# Compile release
RUN mix compile
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
