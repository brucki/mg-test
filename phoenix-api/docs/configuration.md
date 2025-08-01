# Configuration Reference

## Environment Variables

This document describes all environment variables used by the Phoenix API application.

### Polish Data Import Configuration

#### POLISH_API_BASE_URL
- **Description**: Base URL for the Polish government API (dane.gov.pl)
- **Type**: String (URL)
- **Default**: `https://api.dane.gov.pl/1.4`
- **Required**: No
- **Example**: `POLISH_API_BASE_URL=https://api.dane.gov.pl/1.4`

#### POLISH_API_TIMEOUT
- **Description**: HTTP request timeout for Polish API calls in milliseconds
- **Type**: Integer
- **Default**: `30000` (30 seconds)
- **Required**: No
- **Range**: 5000-120000 (5 seconds to 2 minutes)
- **Example**: `POLISH_API_TIMEOUT=45000`

#### POLISH_API_MAX_RETRIES
- **Description**: Maximum number of retry attempts for failed API requests
- **Type**: Integer
- **Default**: `3`
- **Required**: No
- **Range**: 0-10
- **Example**: `POLISH_API_MAX_RETRIES=5`

#### IMPORT_API_TOKEN
- **Description**: Optional API token for securing the import endpoint
- **Type**: String
- **Default**: `nil` (authentication disabled)
- **Required**: No
- **Security**: Should be a strong, randomly generated token (minimum 32 characters)
- **Example**: `IMPORT_API_TOKEN=your-secure-token-here-min-32-chars`

### Configuration File Examples

#### .env.example
```bash
# Polish Data Import Configuration
# Uncomment and modify as needed

# API endpoint configuration
#POLISH_API_BASE_URL=https://api.dane.gov.pl/1.4
#POLISH_API_TIMEOUT=30000
#POLISH_API_MAX_RETRIES=3

# Security configuration
# IMPORTANT: Use a strong token in production
#IMPORT_API_TOKEN=your-secure-token-here-min-32-chars
```

#### config/runtime.exs
```elixir
import Config

# Polish Data Import configuration
config :api, Api.DataImport,
  api_base_url: System.get_env("POLISH_API_BASE_URL", "https://api.dane.gov.pl/1.4"),
  request_timeout: String.to_integer(System.get_env("POLISH_API_TIMEOUT", "30000")),
  max_retries: String.to_integer(System.get_env("POLISH_API_MAX_RETRIES", "3"))

# Import API authentication
if import_token = System.get_env("IMPORT_API_TOKEN") do
  config :api, ApiWeb.ImportController,
    api_token: import_token
end
```

### Environment-Specific Recommendations

#### Development Environment
```bash
# Relaxed timeouts for development
POLISH_API_TIMEOUT=45000
POLISH_API_MAX_RETRIES=5

# Optional: Enable authentication for testing
IMPORT_API_TOKEN=dev-token-for-testing-only
```

#### Testing Environment
```bash
# Shorter timeouts for faster test execution
POLISH_API_TIMEOUT=10000
POLISH_API_MAX_RETRIES=1

# No authentication in tests (unless testing auth specifically)
# IMPORT_API_TOKEN is not set
```

#### Production Environment
```bash
# Production-optimized settings
POLISH_API_TIMEOUT=60000
POLISH_API_MAX_RETRIES=3

# REQUIRED: Strong authentication token
IMPORT_API_TOKEN=prod-secure-random-token-min-32-characters-long
```

### Validation Rules

#### POLISH_API_TIMEOUT
- Must be a positive integer
- Minimum: 5000 (5 seconds)
- Maximum: 120000 (2 minutes)
- Recommended: 30000-60000 for production

#### POLISH_API_MAX_RETRIES
- Must be a non-negative integer
- Minimum: 0 (no retries)
- Maximum: 10 (practical limit)
- Recommended: 3-5 for production

#### IMPORT_API_TOKEN
- If set, must be at least 32 characters long
- Should contain a mix of letters, numbers, and special characters
- Should be unique per environment
- Should be rotated regularly in production

### Configuration Testing

To test your configuration, you can use the following approaches:

#### Check Current Configuration
```elixir
# In IEx console
Application.get_env(:api, Api.DataImport)
Application.get_env(:api, ApiWeb.ImportController)
```

#### Test API Connectivity
```bash
# Test external API connectivity
curl -I https://api.dane.gov.pl/1.4/resources/63929/data?page=1&per_page=1
```

#### Test Import Endpoint
```bash
# Without authentication
curl -X POST http://localhost:4000/import

# With authentication
curl -X POST http://localhost:4000/import \
  -H "Authorization: Bearer your-token-here"
```