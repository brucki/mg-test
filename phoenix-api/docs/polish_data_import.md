# Polish Data Import Documentation

## Overview

The Polish Data Import feature allows system administrators to populate the database with realistic test data by fetching authentic Polish names and surnames from the official government API (dane.gov.pl) and generating random users with proper demographic constraints.

## Configuration

### Environment Variables

The following environment variables can be configured for the Polish Data Import feature:

#### Required Configuration

None - the system works with default values.

#### Optional Configuration

| Variable | Description | Default Value | Example |
|----------|-------------|---------------|---------|
| `POLISH_API_BASE_URL` | Base URL for the Polish government API | `https://api.dane.gov.pl/1.4` | `https://api.dane.gov.pl/1.4` |
| `POLISH_API_TIMEOUT` | HTTP request timeout in milliseconds | `30000` | `45000` |
| `POLISH_API_MAX_RETRIES` | Maximum number of retry attempts for failed requests | `3` | `5` |
| `IMPORT_API_TOKEN` | Optional API token for securing the import endpoint | `nil` (disabled) | `your-secret-token-here` |

### Configuration Examples

#### Development Environment (.env.dev)
```bash
# Optional: Customize API settings
POLISH_API_TIMEOUT=45000
POLISH_API_MAX_RETRIES=5

# Optional: Enable API authentication
IMPORT_API_TOKEN=dev-import-token-123
```

#### Production Environment (.env.prod)
```bash
# Recommended: Enable API authentication in production
IMPORT_API_TOKEN=prod-secure-token-xyz

# Optional: Adjust timeouts for production network conditions
POLISH_API_TIMEOUT=60000
POLISH_API_MAX_RETRIES=3
```

#### Elixir Configuration (config/config.exs)
```elixir
config :api, Api.DataImport,
  api_base_url: System.get_env("POLISH_API_BASE_URL", "https://api.dane.gov.pl/1.4"),
  request_timeout: String.to_integer(System.get_env("POLISH_API_TIMEOUT", "30000")),
  max_retries: String.to_integer(System.get_env("POLISH_API_MAX_RETRIES", "3"))

config :api, ApiWeb.ImportController,
  api_token: System.get_env("IMPORT_API_TOKEN")
```

## API Documentation

### Import Endpoint

#### POST /import

Triggers the Polish data import process to fetch names and surnames from the government API and generate 100 random users.

##### Request

**URL**: `POST /import`

**Headers**:
- `Content-Type: application/json`
- `Authorization: Bearer <token>` (optional, if `IMPORT_API_TOKEN` is configured)

**Body**: Empty (no request body required)

##### Response

###### Success Response (HTTP 200)

```json
{
  "status": "success",
  "message": "Successfully imported Polish user data",
  "data": {
    "users_imported": 100,
    "import_duration_ms": 2500
  }
}
```

**Response Fields**:
- `status`: Always "success" for successful imports
- `message`: Human-readable success message
- `data.users_imported`: Number of users successfully created (always 100)
- `data.import_duration_ms`: Time taken for the import process in milliseconds

###### Error Responses

**HTTP 401 - Unauthorized** (when API token is required but missing/invalid)
```json
{
  "status": "error",
  "message": "Unauthorized access",
  "error_code": "UNAUTHORIZED"
}
```

**HTTP 409 - Conflict** (when import is already in progress)
```json
{
  "status": "error",
  "message": "Import already in progress",
  "error_code": "IMPORT_IN_PROGRESS"
}
```

**HTTP 502 - Bad Gateway** (when external API is unavailable)
```json
{
  "status": "error",
  "message": "External API unavailable",
  "error_code": "EXTERNAL_API_ERROR",
  "details": "Failed to fetch data from dane.gov.pl API"
}
```

**HTTP 500 - Internal Server Error** (for other system errors)
```json
{
  "status": "error",
  "message": "Internal server error during import",
  "error_code": "INTERNAL_ERROR",
  "details": "Database transaction failed"
}
```

##### Example Usage

###### cURL Example (without authentication)
```bash
curl -X POST http://localhost:4000/import \
  -H "Content-Type: application/json"
```

###### cURL Example (with authentication)
```bash
curl -X POST http://localhost:4000/import \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-token-here"
```

###### JavaScript/Fetch Example
```javascript
const response = await fetch('/import', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    // Include if authentication is enabled
    'Authorization': 'Bearer your-api-token-here'
  }
});

const result = await response.json();
console.log('Import result:', result);
```

## Error Codes and Troubleshooting

### Error Code Reference

| Error Code | HTTP Status | Description | Common Causes |
|------------|-------------|-------------|---------------|
| `UNAUTHORIZED` | 401 | API token authentication failed | Missing or invalid API token |
| `IMPORT_IN_PROGRESS` | 409 | Another import is currently running | Concurrent import attempt |
| `EXTERNAL_API_ERROR` | 502 | Failed to fetch data from dane.gov.pl | Network issues, API downtime |
| `INTERNAL_ERROR` | 500 | System error during import process | Database issues, application errors |

### Troubleshooting Guide

#### Problem: "Unauthorized access" (HTTP 401)

**Symptoms**:
- API returns 401 status code
- Error message: "Unauthorized access"

**Causes**:
- `IMPORT_API_TOKEN` is configured but request doesn't include Authorization header
- Invalid or expired API token provided

**Solutions**:
1. Check if `IMPORT_API_TOKEN` environment variable is set
2. Include `Authorization: Bearer <token>` header in request
3. Verify the token value matches the configured environment variable
4. If not using authentication, remove or comment out `IMPORT_API_TOKEN` from configuration

#### Problem: "Import already in progress" (HTTP 409)

**Symptoms**:
- API returns 409 status code
- Error message: "Import already in progress"

**Causes**:
- Another import process is currently running
- Previous import process didn't complete properly

**Solutions**:
1. Wait for the current import to complete (typically 30-60 seconds)
2. Check application logs for any stuck processes
3. Restart the application if import process appears to be stuck
4. Monitor system resources to ensure adequate performance

#### Problem: "External API unavailable" (HTTP 502)

**Symptoms**:
- API returns 502 status code
- Error message: "External API unavailable"
- Logs show HTTP timeout or connection errors

**Causes**:
- dane.gov.pl API is temporarily unavailable
- Network connectivity issues
- Firewall blocking outbound requests
- API rate limiting

**Solutions**:
1. Check dane.gov.pl API status and availability
2. Verify network connectivity from the server
3. Check firewall rules for outbound HTTPS traffic
4. Increase `POLISH_API_TIMEOUT` if requests are timing out
5. Wait and retry later if API is experiencing downtime
6. Check application logs for specific HTTP error details

#### Problem: "Internal server error" (HTTP 500)

**Symptoms**:
- API returns 500 status code
- Error message: "Internal server error during import"
- Application logs show database or system errors

**Causes**:
- Database connection issues
- Insufficient database permissions
- Memory or resource constraints
- Application configuration errors

**Solutions**:
1. Check database connectivity and status
2. Verify database user has INSERT permissions on users table
3. Check available system memory and disk space
4. Review application logs for specific error details
5. Ensure all required dependencies are properly installed
6. Restart the application and database if necessary

### Monitoring and Logging

#### Log Levels and Messages

The import process generates structured logs at different levels:

**INFO Level**:
- Import process start/completion
- Number of users imported
- API request summaries

**DEBUG Level**:
- Individual API requests and responses
- User generation details
- Database transaction information

**WARN Level**:
- Retry attempts for failed requests
- Data validation warnings
- Performance concerns

**ERROR Level**:
- API failures and timeouts
- Database errors
- System exceptions

#### Example Log Output

```
[info] Starting Polish data import process
[debug] Fetching male names from dane.gov.pl API (resource: 63929)
[debug] Successfully fetched 100 male names
[debug] Fetching female names from dane.gov.pl API (resource: 63924)
[debug] Successfully fetched 100 female names
[debug] Fetching male surnames from dane.gov.pl API (resource: 63929)
[debug] Successfully fetched 100 male surnames
[debug] Fetching female surnames from dane.gov.pl API (resource: 63888)
[debug] Successfully fetched 100 female surnames
[info] Generating 100 random users with Polish demographic data
[debug] Starting database transaction for user import
[info] Successfully imported 100 users in 2.5 seconds
```

#### Monitoring Recommendations

1. **Set up alerts** for repeated 502 errors (external API issues)
2. **Monitor import frequency** to detect unusual usage patterns
3. **Track import duration** to identify performance degradation
4. **Log retention** should keep import logs for at least 30 days
5. **Database monitoring** for user table growth and performance

### Performance Considerations

#### Expected Performance

- **Import duration**: 2-10 seconds under normal conditions
- **API requests**: 4 requests to dane.gov.pl (one per data type)
- **Database operations**: 1 batch insert of 100 users
- **Memory usage**: Minimal (< 10MB additional during import)

#### Performance Optimization

1. **Increase timeout values** for slow network conditions
2. **Monitor API rate limits** to avoid being blocked
3. **Use database connection pooling** for better performance
4. **Consider caching** API responses during development/testing
5. **Implement monitoring** for import duration trends

### Security Considerations

#### API Token Security

- Store API tokens in environment variables, never in code
- Use strong, randomly generated tokens (minimum 32 characters)
- Rotate tokens regularly in production environments
- Consider using different tokens for different environments

#### Network Security

- Ensure outbound HTTPS connections are allowed to dane.gov.pl
- Consider using a proxy or firewall rules to restrict API access
- Monitor for unusual API usage patterns
- Implement rate limiting if the endpoint is exposed publicly

#### Data Security

- Generated user data is for testing purposes only
- Consider data retention policies for imported test data
- Ensure proper database access controls
- Log access to the import endpoint for audit purposes