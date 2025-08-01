# Find eligible builder and runner images on Docker Hub. We use Ubuntu/Debian
# instead of Alpine to avoid DNS resolution issues in production.
#
# https://hub.docker.com/r/hexpm/elixir/tags?page=1&name=ubuntu
# https://hub.docker.com/_/ubuntu?tab=tags
#
# This file is based on these images:
#
#   - https://hub.docker.com/r/hexpm/elixir/tags - for the build image
#   - https://hub.docker.com/_/debian?tab=tags&page=1&name=bullseye-20250630-slim - for the release image
#   - https://pkgs.org/ - resource for finding needed packages
#   - Ex: hexpm/elixir:1.18.4-erlang-28.0.1-debian-bullseye-20250630-slim
#
ARG ELIXIR_VERSION=1.18.4
ARG OTP_VERSION=28.0.1
ARG DEBIAN_VERSION=bullseye-20250630-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} as builder

# install build dependencies and tools
RUN apt-get update -y && apt-get install -y build-essential git sudo wget \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Install gosu for better user switching
RUN wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.16/gosu-$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && chmod +x /usr/local/bin/gosu

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv

COPY lib lib

# Compile the release
RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

COPY rel rel
RUN mix release

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${BUILDER_IMAGE} as runner

# Add PostgreSQL repository and install client and gosu
RUN apt-get update -y && \
  apt-get install -y wget gnupg2 lsb-release && \
  sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && \
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
  apt-get update -y && \
  apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates postgresql-client-15 && \
  # Install gosu for better user switching
  wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.16/gosu-$(dpkg --print-architecture | awk -F- '{ print $NF }')" && \
  chmod +x /usr/local/bin/gosu && \
  gosu nobody true && \
  apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"

# Copy the built release and necessary files
COPY --from=builder --chown=nobody:root /app/_build/prod/rel/api ./

# Copy the config directory
COPY --from=builder --chown=nobody:root /app/config ./config

# Copy the mix.exs and mix.lock files
COPY --from=builder --chown=nobody:root /app/mix.exs .
COPY --from=builder --chown=nobody:root /app/mix.lock .

# Copy the priv directory for migrations
COPY --from=builder --chown=nobody:root /app/priv ./priv

# Set environment
ENV MIX_ENV=prod
ENV PORT=4000
ENV PHX_HOST=localhost
ENV DATABASE_URL=postgresql://postgres:postgres@db:5432/phoenix_app

# Migration script will be copied from overlays during release build

# Create a simple entrypoint script
RUN echo '#!/bin/sh\nset -e\n\n# Wait for PostgreSQL to be ready\necho "Waiting for PostgreSQL..."\nuntil pg_isready -h db -p 5432 -U postgres; do\n  echo "PostgreSQL is unavailable - sleeping"\n  sleep 1\ndone\n\necho "PostgreSQL is up - checking if database exists"\n\n# Check if database exists, if not create it\nif ! PGPASSWORD=postgres psql -h db -U postgres -lqt | cut -d \\| -f 1 | grep -qw phoenix_app; then\n  echo "Database phoenix_app does not exist, creating..."\n  PGPASSWORD=postgres createdb -h db -U postgres phoenix_app\nelse\n  echo "Database phoenix_app already exists"\nfi\n\necho "Running migrations..."\n/app/bin/migrate\n\necho "Starting Phoenix server..."\nexec /app/bin/server' > /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh

# Create appuser and set permissions
RUN useradd -m -d /home/appuser -s /bin/bash appuser && \
    chown -R appuser:appuser /app

# Copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Set user
USER appuser

# The command to run when the container starts
CMD ["/app/entrypoint.sh"]
