#!/bin/sh
set -e

# Set global NODE_OPTIONS to suppress deprecation warnings
export NODE_OPTIONS="--no-deprecation"

echo "Starting PayloadCMS application..."

# Basic environment checks
if [ -z "$DATABASE_URI" ]; then
  echo "ERROR: DATABASE_URI environment variable is not set"
  exit 1
fi

if [ -z "$PAYLOAD_SECRET" ]; then
  echo "ERROR: PAYLOAD_SECRET environment variable is not set"
  exit 1
fi

# Parse DB connection params
DB_HOST=$(echo $DATABASE_URI | sed -E 's/.*@([^:]+):.*/\1/')
DB_PORT=$(echo $DATABASE_URI | sed -E 's/.*:([0-9]+)\/.*/\1/')
DB_NAME=$(echo $DATABASE_URI | sed -E 's/.*\/([^?]+).*/\1/')
DB_USER=$(echo $DATABASE_URI | sed -E 's/.*:\/\/([^:]+):.*/\1/')

# Wait for DB
echo "Waiting for PostgreSQL at $DB_HOST:$DB_PORT..."
for i in $(seq 1 30); do
  if pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" > /dev/null 2>&1; then
    echo "PostgreSQL is ready!"
    break
  fi
  
  if [ $i -eq 30 ]; then
    echo "ERROR: PostgreSQL not available after 30 attempts"
    exit 1
  fi
  
  echo "Waiting for PostgreSQL... attempt $i/30"
  sleep 3
done

# Check if migrations directory exists
if [ ! -d "/app/src/migrations" ] || [ -z "$(ls -A /app/src/migrations 2>/dev/null)" ]; then
  echo "Migrations directory is empty or doesn't exist, creating..."
  mkdir -p /app/src/migrations
  
  # Create initial migration if directory is empty
  if [ -z "$(ls -A /app/src/migrations 2>/dev/null)" ]; then
    echo "the /src/migration directory is empty."
    echo "If you would like [entrypoint.sh] to create an initial migration, comment its create migration command back into the script"
    echo "For now, leaving it commented out for clarity, now that an initial migration was created on the server"
    echo "Note: This is a Production-First with Local Sync migration methodology-- the remote server is the origin of truth"
    echo "As needed, we pull the remote servers data to local dev machines for development"
    echo "Creating initial migration..."
    pnpm run payload:migrate:create --name initial
  fi
fi

# Run migrations
echo "Running database migrations..."
pnpm run payload:migrate

# Build if needed (for CICD skip build mode)
if [ -f .next/skip-build ]; then
  echo "Running Next.js build..."
  export NEXT_SKIP_DB_CONNECT=true
  # Run build and handle postbuild via exec to ensure environment variables are properly passed
  pnpm run build && pnpm run postbuild
fi

# Start application
echo "Starting Next.js application..."
exec pnpm run start