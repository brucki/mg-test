#!/bin/sh
set -e

# Create appuser if it doesn't exist
if ! id -u appuser >/dev/null 2>&1; then
  echo "Creating appuser..."
  adduser --disabled-password --gecos '' --home /home/appuser appuser
  mkdir -p /home/appuser/.mix/archives
  chown -R appuser:appuser /home/appuser
  
  # Install Hex and Rebar as root before dropping privileges
  echo "Installing Hex and Rebar..."
  mix local.hex --force
  mix local.rebar --force
  
  # Copy Hex and Rebar to appuser's home
  cp -r /root/.mix /home/appuser/ && \
    chown -R appuser:appuser /home/appuser/.mix
fi

# Set MIX_HOME to a writable directory
export MIX_HOME=/home/appuser/.mix
export PATH="$MIX_HOME/bin:$PATH"

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL..."
until pg_isready -h db -p 5432 -U postgres; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 1
done

echo "PostgreSQL is up - checking if database exists"

# Check if database exists, if not create it
if ! PGPASSWORD=postgres psql -h db -U postgres -lqt | cut -d \| -f 1 | grep -qw phoenix_app; then
  echo "Database phoenix_app does not exist, creating..."
  PGPASSWORD=postgres createdb -h db -U postgres phoenix_app
else
  echo "Database phoenix_app already exists"
fi

# Run migrations as appuser
echo "Running migrations..."
gosu appuser /app/bin/migrate

# Start the server as appuser
echo "Starting Phoenix server..."
exec gosu appuser /app/bin/server
