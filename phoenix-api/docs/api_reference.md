# API Reference

## Import Endpoints

### POST /import

Triggers the Polish data import process to fetch authentic Polish names and surnames from the government API and generate 100 random users with realistic demographic data.

#### Request

**Method**: `POST`  
**URL**: `/import`  
**Content-Type**: `application/json`

##### Headers

| Header | Required | Description | Example |
|--------|----------|-------------|---------|
| `Content-Type` | Yes | Must be `application/json` | `application/json` |
| `Authorization` | Conditional | Required if `IMPORT_API_TOKEN` is configured | `Bearer your-api-token` |

##### Request Body

No request body is required. Send an empty JSON object `{}` or no body at all.

##### Example Requests

###### Basic Request (No Authentication)
```http
POST /import HTTP/1.1
Host: localhost:4000
Content-Type: application/json
```

###### Authenticated Request
```http
POST /import HTTP/1.1
Host: localhost:4000
Content-Type: application/json
Authorization: Bearer your-secure-api-token-here
```

###### cURL Examples
```bash
# Basic request
curl -X POST http://localhost:4000/import \
  -H "Content-Type: application/json"

# Authenticated request
curl -X POST http://localhost:4000/import \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-secure-api-token-here"

# With verbose output for debugging
curl -X POST http://localhost:4000/import \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-secure-api-token-here" \
  -v
```

#### Responses

##### Success Response (HTTP 200)

**Status Code**: `200 OK`  
**Content-Type**: `application/json`

```json
{
  "status": "success",
  "message": "Successfully imported Polish user data",
  "data": {
    "users_imported": 100,
    "import_duration_ms": 2847
  }
}
```

**Response Fields**:
- `status` (string): Always "success" for successful operations
- `message` (string): Human-readable success message
- `data` (object): Import result details
  - `users_imported` (integer): Number of users created (always 100)
  - `import_duration_ms` (integer): Total import time in milliseconds

##### Error Responses

###### HTTP 401 - Unauthorized

Returned when API token authentication is required but missing or invalid.

```json
{
  "status": "error",
  "message": "Unauthorized access",
  "error_code": "UNAUTHORIZED"
}
```

**Common Causes**:
- Missing `Authorization` header when `IMPORT_API_TOKEN` is configured
- Invalid or expired API token
- Malformed `Authorization` header format

###### HTTP 409 - Conflict

Returned when an import process is already running.

```json
{
  "status": "error",
  "message": "Import already in progress",
  "error_code": "IMPORT_IN_PROGRESS"
}
```

**Common Causes**:
- Concurrent import requests
- Previous import process still running
- System not properly cleaned up after failed import

###### HTTP 502 - Bad Gateway

Returned when the external Polish government API is unavailable.

```json
{
  "status": "error",
  "message": "External API unavailable",
  "error_code": "EXTERNAL_API_ERROR",
  "details": "Failed to fetch data from dane.gov.pl API after 3 retry attempts"
}
```

**Common Causes**:
- dane.gov.pl API is down or experiencing issues
- Network connectivity problems
- Firewall blocking outbound requests
- API rate limiting or throttling

###### HTTP 500 - Internal Server Error

Returned for system errors during the import process.

```json
{
  "status": "error",
  "message": "Internal server error during import",
  "error_code": "INTERNAL_ERROR",
  "details": "Database transaction failed: connection timeout"
}
```

**Common Causes**:
- Database connectivity issues
- Insufficient system resources
- Application configuration errors
- Unexpected system exceptions

#### Response Examples by Programming Language

##### JavaScript/Fetch
```javascript
async function importPolishData() {
  try {
    const response = await fetch('/import', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer your-api-token-here' // if auth enabled
      }
    });

    const result = await response.json();
    
    if (response.ok) {
      console.log(`Successfully imported ${result.data.users_imported} users`);
      console.log(`Import took ${result.data.import_duration_ms}ms`);
    } else {
      console.error(`Import failed: ${result.message}`);
      console.error(`Error code: ${result.error_code}`);
    }
  } catch (error) {
    console.error('Network error:', error);
  }
}
```

##### Python/Requests
```python
import requests
import json

def import_polish_data():
    url = 'http://localhost:4000/import'
    headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer your-api-token-here'  # if auth enabled
    }
    
    try:
        response = requests.post(url, headers=headers)
        result = response.json()
        
        if response.status_code == 200:
            print(f"Successfully imported {result['data']['users_imported']} users")
            print(f"Import took {result['data']['import_duration_ms']}ms")
        else:
            print(f"Import failed: {result['message']}")
            print(f"Error code: {result['error_code']}")
            
    except requests.exceptions.RequestException as e:
        print(f"Network error: {e}")
```

##### PHP/cURL
```php
<?php
function importPolishData() {
    $url = 'http://localhost:4000/import';
    $headers = [
        'Content-Type: application/json',
        'Authorization: Bearer your-api-token-here' // if auth enabled
    ];
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    $result = json_decode($response, true);
    
    if ($httpCode === 200) {
        echo "Successfully imported " . $result['data']['users_imported'] . " users\n";
        echo "Import took " . $result['data']['import_duration_ms'] . "ms\n";
    } else {
        echo "Import failed: " . $result['message'] . "\n";
        echo "Error code: " . $result['error_code'] . "\n";
    }
}
?>
```

#### Rate Limiting

The import endpoint implements basic concurrency protection:

- **Concurrent Requests**: Only one import can run at a time
- **Rate Limiting**: No explicit rate limiting, but imports typically take 2-10 seconds
- **Retry Strategy**: Wait for current import to complete before retrying

#### Data Sources

The import process fetches data from the following Polish government API endpoints:

| Data Type | Resource ID | API Endpoint |
|-----------|-------------|--------------|
| Male Names | 63929 | `https://api.dane.gov.pl/1.4/resources/63929/data?page=1&per_page=100` |
| Female Names | 63924 | `https://api.dane.gov.pl/1.4/resources/63924/data?page=1&per_page=100` |
| Male Surnames | 63929 | `https://api.dane.gov.pl/1.4/resources/63929/data?page=1&per_page=100` |
| Female Surnames | 63888 | `https://api.dane.gov.pl/1.4/resources/63888/data?page=1&per_page=100` |

#### Generated User Data

Each import creates exactly 100 users with the following characteristics:

- **Names**: Randomly selected from the 100 most popular Polish names
- **Surnames**: Randomly selected from the 100 most popular Polish surnames
- **Gender**: Randomly assigned (male/female) with consistent name/surname matching
- **Birth Date**: Randomly generated between January 1, 1970 and December 31, 2024
- **Data Quality**: All generated data passes existing User model validations

#### Security Considerations

- **Authentication**: Optional API token authentication via `Authorization` header
- **Input Validation**: No user input required, reducing attack surface
- **Rate Protection**: Concurrent import prevention
- **Error Handling**: Generic error messages to prevent information disclosure
- **Logging**: All import attempts are logged for audit purposes

#### Monitoring and Observability

The import endpoint provides several monitoring points:

- **Success Rate**: Track HTTP 200 vs error responses
- **Performance**: Monitor `import_duration_ms` values
- **External Dependencies**: Track HTTP 502 errors for API availability
- **Concurrency**: Monitor HTTP 409 errors for usage patterns
- **Authentication**: Track HTTP 401 errors if auth is enabled