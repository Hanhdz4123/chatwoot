#!/usr/bin/env bash
set -euo pipefail

# Deploy Chatwoot from source on a VPS (Ubuntu/Debian with Docker + Compose v2).
# Run from the repo root on the server, after copying .env for production.

COMPOSE_FILES=(-f docker-compose.production.yaml -f docker-compose.build.yaml)
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$APP_DIR"

if [[ ! -f .env ]]; then
  echo "Missing .env — copy .env.example and set SECRET_KEY_BASE, FRONTEND_URL, POSTGRES_PASSWORD, REDIS_PASSWORD, etc."
  exit 1
fi

echo "==> Building production image (this can take 15–30 minutes on a small VPS)..."
docker compose "${COMPOSE_FILES[@]}" build --pull

echo "==> Starting postgres + redis..."
docker compose "${COMPOSE_FILES[@]}" up -d postgres redis

echo "==> Waiting for postgres..."
sleep 10

echo "==> Running database prepare..."
docker compose "${COMPOSE_FILES[@]}" run --rm rails bundle exec rails db:chatwoot_prepare

echo "==> Starting rails + sidekiq..."
docker compose "${COMPOSE_FILES[@]}" up -d rails sidekiq

echo "==> Done. Rails listens on 127.0.0.1:3000 — put nginx/caddy in front with SSL."
docker compose "${COMPOSE_FILES[@]}" ps
