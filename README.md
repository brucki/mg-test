# Morizon-Gratka Test Project

This is a test project that consists of a Symfony application and a Phoenix API, both connected to a PostgreSQL database.

## Prerequisites

- Docker (with Docker Compose)
- Git (for cloning the repository)

## Project Structure

- `symfony-app/` - Symfony PHP application
- `phoenix-api/` - Phoenix/Elixir API
- `docker-compose.yml` - Docker Compose configuration

## Getting Started

1. **Clone the repository** (if you haven't already):
   ```bash
   git clone <repository-url>
   cd morizon-gratka
   ```

2. **Start the services** using Makefile:
   ```bash
   make
   ```

   This will start the following services:
   - PostgreSQL database on port 5432
   - Phoenix API on port 4000
   - Symfony application on port 8000

3. **Access the applications**:
   - Symfony application: http://localhost:8000
   - Phoenix API: http://localhost:4000
   - Database: localhost:5432 (username: postgres, password: postgres)

## Stopping the Services

To stop all services:
```bash
make stop
```

To stop and remove all containers, networks, and volumes:
```bash
make down
```

## Development

### Symfony Application
- Located in the `symfony-app/` directory
- Automatically synchronized with the container using volumes
- Access the container: `docker compose exec symfony bash`

### Phoenix API
- Located in the `phoenix-api/` directory
- Access the container: `docker compose exec phoenix bash`

### Database
- PostgreSQL 15
- Default credentials:
  - Username: postgres
  - Password: postgres
  - Database: postgres

## Troubleshooting

If you encounter any issues:
1. Check the logs: `docker compose logs`
2. Ensure all services are running: `docker compose ps`
3. Rebuild the containers if needed: `docker compose up -d --build`

## Data Sources

This project uses data from the Polish PESEL registry, specifically:

### First Names
- **Male Names**: [PESEL Registry - Male First Names](https://api.dane.gov.pl/1.4/resources/63929/data?page=1&per_page=100)
- **Female Names**: [PESEL Registry - Female First Names](https://api.dane.gov.pl/1.4/resources/63924/data?page=1&per_page=100)

### Last Names
- **Male Last Names**: [PESEL Registry - Male Last Names](https://api.dane.gov.pl/1.4/resources/63892/data?page=1&per_page=100)
- **Female Last Names**: [PESEL Registry - Female Last Names](https://api.dane.gov.pl/1.4/resources/63888/data?page=1&per_page=100)

## License

This project is for testing purposes only.
