# Lumina Deployment Guide

## Prerequisites

- Fedora VPS (Hetzner or similar)
- Docker & Docker Compose installed
- Domain configured in Cloudflare

## Initial Setup

### 1. Install Docker on Fedora

```bash
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
```

### 2. Clone Repository

```bash
git clone https://github.com/yourusername/lumina.git
cd lumina
```

### 3. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set:

- `SECRET_KEY_BASE` (generate with `mix phx.gen.secret`)
- `TOKEN_SIGNING_SECRET` (generate with `mix phx.gen.secret`)
- `PHX_HOST` (your domain)
- `LUMINA_BACKUP_PASSWORD`

### 4. Build and Start

```bash
docker-compose up -d --build
```

### 5. Configure Cloudflare

1. Add A record pointing to your VPS IP
2. Enable Cloudflare proxy (orange cloud)
3. Set SSL/TLS to "Full"

### 6. Run Migrations

```bash
docker-compose exec lumina bin/lumina eval "Lumina.Release.migrate"
```

### 7. Run Seeds (first run only)

Create the admin user (set `LUMINA_ADMIN_EMAIL` and `LUMINA_ADMIN_PASSWORD` in `.env` first):

```bash
docker-compose exec lumina bin/lumina eval "Lumina.Release.seeds"
```

## Updating

```bash
git pull
docker-compose up -d --build
```

## Backups

Access `/admin/backup` and enter backup password to download.

## Logs

```bash
docker-compose logs -f lumina
```

## Troubleshooting

### Check if containers are running

```bash
docker-compose ps
```

### Restart services

```bash
docker-compose restart
```

### View database

```bash
docker-compose exec lumina bin/lumina remote
```

### Access shell

```bash
docker-compose exec lumina sh
```

## Environment Variables

All environment variables should be set in `.env`. See README for full table. Required and common:

- `SECRET_KEY_BASE` - Phoenix secret (generate with `mix phx.gen.secret`)
- `TOKEN_SIGNING_SECRET` - JWT signing (generate with `mix phx.gen.secret`)
- `PHX_HOST` - Your domain (e.g. `lumina.yourdomain.com`)
- `LUMINA_BACKUP_PASSWORD` - Password for `/admin/backup`
- `LUMINA_ADMIN_EMAIL` - Admin user email (seeded on first run; default `admin@example.com`)
- `LUMINA_ADMIN_PASSWORD` - Admin user password (seeded; default `change-me-in-production` — change in production)
- `DATABASE_PATH` - SQLite path (default `/app/data/lumina.db`)
- `PORT` - App port (default `4000`), `POOL_SIZE` - DB pool (default `5`)

Optional: `GOOGLE_OAUTH_CLIENT_ID`, `GOOGLE_OAUTH_CLIENT_SECRET`, `GOOGLE_OAUTH_REDIRECT_URI` for Sign in with Google (see README).

## Production Checklist

- [ ] Set strong `SECRET_KEY_BASE`, `TOKEN_SIGNING_SECRET`, `LUMINA_BACKUP_PASSWORD`; change `LUMINA_ADMIN_PASSWORD`
- [ ] Never commit `.env`; use strong random secrets; keep deps up to date
- [ ] Configure domain in Cloudflare; SSL/TLS (via Caddy); firewall (ports 80, 443); Cloudflare for DDoS
- [ ] Regular backups (e.g. `/admin/backup` or volume copy); monitoring

## File Storage

- Database: `./data/lumina.db`
- Uploads: `./uploads/originals/` and `./uploads/thumbnails/`

Both directories are mounted as volumes and persist across container restarts.

### Volume permissions

The Lumina container runs as a non-root user. Ensure `./data` and `./uploads` exist on the host and are writable by the container user. If you see permission errors, create the directories and adjust ownership (e.g. `chown 1000:1000 ./data ./uploads` if the container user has UID 1000).

## Scaling Considerations

For many users: consider PostgreSQL, S3-compatible storage for uploads, and Redis/caching. See README for more.
