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

All environment variables should be set in `.env`:

- `SECRET_KEY_BASE` - Phoenix secret key (generate with `mix phx.gen.secret`)
- `TOKEN_SIGNING_SECRET` - JWT signing secret (generate with `mix phx.gen.secret`)
- `DATABASE_PATH` - Path to SQLite database (default: `/app/data/lumina.db`)
- `PHX_HOST` - Your domain name (e.g., `lumina.yourdomain.com`)
- `LUMINA_BACKUP_PASSWORD` - Password for admin backup page
- `PORT` - Application port (default: `4000`)
- `POOL_SIZE` - Database pool size (default: `5`)

## Production Checklist

- [ ] Set strong `SECRET_KEY_BASE`
- [ ] Set strong `TOKEN_SIGNING_SECRET`
- [ ] Set strong `LUMINA_BACKUP_PASSWORD`
- [ ] Configure domain in Cloudflare
- [ ] SSL/TLS enabled (via Caddy)
- [ ] Firewall configured (allow ports 80, 443)
- [ ] Regular backups scheduled
- [ ] Monitoring set up

## Security Notes

1. Never commit `.env` file to version control
2. Use strong, random passwords for all secrets
3. Keep dependencies up to date
4. Enable firewall on VPS
5. Use Cloudflare for DDoS protection
6. Regularly backup data and uploads

## File Storage

- Database: `./data/lumina.db`
- Uploads: `./uploads/originals/` and `./uploads/thumbnails/`

Both directories are mounted as volumes and persist across container restarts.

## Scaling Considerations

For production use with many users:

1. Consider using PostgreSQL instead of SQLite
2. Move uploads to S3-compatible storage
3. Add Redis for caching
4. Use separate Oban queues for different job types
5. Enable CDN for static assets
