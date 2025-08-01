# Symfony 6 Docker Application

This is a Symfony 6 application configured to run in Docker without database dependencies.

## Features

- **Symfony 6** - Latest Symfony framework
- **PHP 8.2** - Modern PHP version with Alpine Linux
- **Nginx** - High-performance web server
- **No Database** - Lightweight setup without SQL database dependencies
- **Port 8000** - Application exposed on port 8000

## Quick Start

### Build the Docker image

```bash
docker build -t symfony-app .
```

### Run the container

```bash
docker run -p 8000:8000 symfony-app
```

The application will be available at: http://localhost:8000

### Health Check

You can check if the application is running:

```bash
curl http://localhost:8000/health
```

## Development

### Project Structure

```
symfony-app/
├── docker/
│   ├── nginx/          # Nginx configuration
│   ├── php/            # PHP and PHP-FPM configuration
│   └── supervisor/     # Supervisor configuration
├── public/             # Web root (Symfony public directory)
├── src/                # Symfony source code
├── config/             # Symfony configuration
├── templates/          # Twig templates
├── Dockerfile          # Docker configuration
└── README.md           # This file
```

### Configuration Files

- **nginx.conf** - Main Nginx configuration
- **default.conf** - Symfony-specific Nginx virtual host
- **php.ini** - PHP configuration optimized for Symfony
- **php-fpm.conf** - PHP-FPM process manager configuration
- **supervisord.conf** - Supervisor configuration to manage nginx and php-fpm

### Included PHP Extensions

- **mbstring** - Multibyte string handling
- **gd** - Image processing
- **intl** - Internationalization
- **opcache** - PHP opcode caching
- **xml** - XML processing
- **bcmath** - Arbitrary precision mathematics
- **exif** - Image metadata reading
- **pcntl** - Process control

### Performance Optimizations

- **OPcache enabled** - PHP opcode caching for better performance
- **Nginx gzip compression** - Reduced bandwidth usage
- **Static file caching** - Long-term caching for assets
- **PHP-FPM optimization** - Tuned process management
- **Supervisor** - Reliable process management

### Security Features

- **Security headers** - X-Frame-Options, X-Content-Type-Options, etc.
- **Hidden file protection** - Deny access to sensitive files
- **PHP file restrictions** - Only index.php can be executed
- **Directory access control** - Restricted access to application directories

## Customization

### Environment Variables

You can customize the application by setting environment variables:

```bash
docker run -p 8000:8000 \
  -e APP_ENV=prod \
  -e APP_SECRET=your-secret-key \
  symfony-app
```

### Volume Mounting

For development, you can mount your source code:

```bash
docker run -p 8000:8000 \
  -v $(pwd):/var/www/html \
  symfony-app
```

### Custom Configuration

To override configuration files, you can mount them as volumes:

```bash
docker run -p 8000:8000 \
  -v $(pwd)/custom-nginx.conf:/etc/nginx/conf.d/default.conf \
  symfony-app
```

## Troubleshooting

### Check Container Logs

```bash
docker logs <container-id>
```

### Access Container Shell

```bash
docker exec -it <container-id> /bin/sh
```

### Check Process Status

```bash
docker exec -it <container-id> supervisorctl status
```

### Nginx Logs

```bash
docker exec -it <container-id> tail -f /var/log/nginx/access.log
docker exec -it <container-id> tail -f /var/log/nginx/error.log
```

### PHP-FPM Logs

```bash
docker exec -it <container-id> tail -f /var/log/php-fpm-error.log
```

## Production Deployment

For production deployment, consider:

1. **Multi-stage builds** - Separate build and runtime stages
2. **Security scanning** - Regular vulnerability scans
3. **Resource limits** - Set appropriate CPU and memory limits
4. **Health checks** - Configure Docker health checks
5. **Logging** - Centralized log management
6. **Monitoring** - Application performance monitoring

### Example Production Run

```bash
docker run -d \
  --name symfony-app \
  --restart unless-stopped \
  -p 8000:8000 \
  --memory=512m \
  --cpus=1.0 \
  symfony-app
```