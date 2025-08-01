# Phoenix API

A Phoenix-based API application with Polish demographic data import functionality.

## Features

- **Users REST API**: Complete CRUD operations for user management
- **Polish Data Import**: Import authentic Polish names and surnames from government APIs
- **User Generation**: Generate realistic test users with proper demographic constraints
- **JSON API**: RESTful endpoints with JSON responses
- **Authentication**: Optional API token authentication for import operations
- **Comprehensive Logging**: Detailed logging for monitoring and debugging

## Quick Start

### Prerequisites

- Elixir 1.14+
- Phoenix Framework
- PostgreSQL database
- Internet connection (for fetching data from dane.gov.pl)

### Installation

1. Clone the repository
2. Install dependencies: `mix deps.get`
3. Set up the database: `mix ecto.setup`
4. Start the server: `mix phx.server`

### Basic Usage

Import Polish demographic data:

```bash
curl -X POST http://localhost:4000/import \
  -H "Content-Type: application/json"
```

## Documentation

### Core Documentation

- **[Polish Data Import Guide](docs/polish_data_import.md)** - Complete feature documentation
- **[API Reference](docs/api_reference.md)** - Detailed API endpoint documentation
- **[Configuration Reference](docs/configuration.md)** - Environment variables and setup

### Quick Links

- [Configuration](#configuration)
- [API Usage](#api-usage)
- [Error Handling](#error-handling)
- [Troubleshooting](#troubleshooting)

## Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `IMPORT_API_TOKEN` | API token for import endpoint security | `nil` | No |
| `POLISH_API_TIMEOUT` | API request timeout (ms) | `30000` | No |
| `POLISH_API_MAX_RETRIES` | Max retry attempts | `3` | No |

### Example Configuration

```bash
# .env
IMPORT_API_TOKEN=your-secure-token-here
POLISH_API_TIMEOUT=45000
POLISH_API_MAX_RETRIES=5
```

See [Configuration Reference](docs/configuration.md) for complete details.

## API Usage

### Users API

**GET /users** - List all users
**GET /users/:id** - Get specific user
**POST /users** - Create new user
**PUT /users/:id** - Update user
**DELETE /users/:id** - Delete user

```bash
# List all users
curl -X GET http://localhost:4000/users

# Create new user
curl -X POST http://localhost:4000/users \
  -H "Content-Type: application/json" \
  -d '{"user": {"first_name": "Jan", "last_name": "Kowalski", "gender": "male", "birthdate": "1990-01-15"}}'
```

### Import Endpoint

**POST /import** - Import Polish demographic data

```bash
# Basic usage
curl -X POST http://localhost:4000/import

# With authentication
curl -X POST http://localhost:4000/import \
  -H "Authorization: Bearer your-token"
```

See [Users API Documentation](docs/users_api.md) and [Import API Reference](docs/api_reference.md) for complete documentation.

## Error Handling

### Common Error Codes

| Code | Status | Description |
|------|--------|-------------|
| `UNAUTHORIZED` | 401 | Invalid or missing API token |
| `IMPORT_IN_PROGRESS` | 409 | Another import is running |
| `EXTERNAL_API_ERROR` | 502 | Polish government API unavailable |
| `INTERNAL_ERROR` | 500 | System error during import |

## Troubleshooting

### Quick Fixes

**401 Unauthorized**: Check `IMPORT_API_TOKEN` configuration  
**409 Conflict**: Wait for current import to complete  
**502 Bad Gateway**: Verify internet connection and API availability  
**500 Internal Error**: Check database connectivity and logs  

See [Polish Data Import Guide](docs/polish_data_import.md#troubleshooting-guide) for detailed troubleshooting.

## Development

### Running Tests

```bash
# Run all tests
mix test

# Run specific test file
mix test test/api_web/controllers/import_controller_test.exs

# Run with coverage
mix test --cover
```

### Code Quality

```bash
# Format code
mix format

# Run static analysis
mix credo

# Check dependencies
mix deps.audit
```

## Data Sources

This application fetches data from the official Polish government API:

- **API**: [dane.gov.pl](https://dane.gov.pl)
- **Data**: Most popular Polish names and surnames
- **Usage**: Generates 100 realistic test users per import

## Security

- Optional API token authentication
- Input validation and sanitization
- Secure error handling (no sensitive data exposure)
- Comprehensive audit logging

## Performance

- **Import Duration**: 2-10 seconds typical
- **Concurrent Protection**: One import at a time
- **Resource Usage**: Minimal memory footprint
- **Database**: Batch operations for efficiency

## Support

### Documentation
- [Users REST API](docs/users_api.md) - Complete CRUD API documentation
- [Polish Data Import Guide](docs/polish_data_import.md) - Feature overview and usage
- [Import API Reference](docs/api_reference.md) - Import endpoint documentation
- [Configuration Reference](docs/configuration.md) - Setup and environment variables

### Getting Help
1. Check the troubleshooting guide in the documentation
2. Review application logs for error details
3. Verify configuration and network connectivity
4. Test with minimal configuration first

## License

[Add your license information here]

## Contributing

[Add contributing guidelines here]