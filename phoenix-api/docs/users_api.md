# Users REST API Documentation

## Overview

The Users API provides full CRUD operations for managing user data. All endpoints return JSON responses and follow REST conventions.

## Base URL

```
http://localhost:4000
```

## Endpoints

### GET /users

Lists all users in the system.

**Request:**
```http
GET /users
Accept: application/json
```

**Response (200 OK):**
```json
{
  "data": [
    {
      "id": 1,
      "first_name": "Jan",
      "last_name": "Kowalski",
      "gender": "male",
      "birthdate": "1990-01-15",
      "inserted_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-15T10:30:00Z"
    },
    {
      "id": 2,
      "first_name": "Anna",
      "last_name": "Nowak",
      "gender": "female",
      "birthdate": "1985-05-20",
      "inserted_at": "2024-01-15T11:00:00Z",
      "updated_at": "2024-01-15T11:00:00Z"
    }
  ],
  "meta": {
    "total_count": 2,
    "count": 2
  }
}
```

**Headers:**
- `X-Total-Count: 2` - Total number of users

### GET /users/:id

Retrieves a specific user by ID.

**Request:**
```http
GET /users/1
Accept: application/json
```

**Response (200 OK):**
```json
{
  "data": {
    "id": 1,
    "first_name": "Jan",
    "last_name": "Kowalski",
    "gender": "male",
    "birthdate": "1990-01-15",
    "inserted_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

**Response (404 Not Found):**
```json
{
  "error": "User not found"
}
```

### POST /users

Creates a new user.

**Request:**
```http
POST /users
Content-Type: application/json

{
  "user": {
    "first_name": "Jan",
    "last_name": "Kowalski",
    "gender": "male",
    "birthdate": "1990-01-15"
  }
}
```

**Response (201 Created):**
```json
{
  "data": {
    "id": 3,
    "first_name": "Jan",
    "last_name": "Kowalski",
    "gender": "male",
    "birthdate": "1990-01-15",
    "inserted_at": "2024-01-15T12:00:00Z",
    "updated_at": "2024-01-15T12:00:00Z"
  }
}
```

**Headers:**
- `Location: /users/3`

**Response (422 Unprocessable Entity):**
```json
{
  "error": "Validation failed",
  "details": {
    "first_name": ["can't be blank"],
    "last_name": ["can't be blank"],
    "gender": ["can't be blank"],
    "birthdate": ["can't be blank"]
  }
}
```

**Response (400 Bad Request):**
```json
{
  "error": "Missing 'user' parameter in request body"
}
```

### PUT /users/:id

Updates an existing user.

**Request:**
```http
PUT /users/1
Content-Type: application/json

{
  "user": {
    "first_name": "Anna",
    "last_name": "Nowak",
    "gender": "female",
    "birthdate": "1985-05-20"
  }
}
```

**Response (200 OK):**
```json
{
  "data": {
    "id": 1,
    "first_name": "Anna",
    "last_name": "Nowak",
    "gender": "female",
    "birthdate": "1985-05-20",
    "inserted_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T12:30:00Z"
  }
}
```

**Response (404 Not Found):**
```json
{
  "error": "User not found"
}
```

**Response (422 Unprocessable Entity):**
```json
{
  "error": "Validation failed",
  "details": {
    "first_name": ["can't be blank"]
  }
}
```

**Response (400 Bad Request):**
```json
{
  "error": "Missing 'user' parameter in request body"
}
```

### DELETE /users/:id

Deletes a user.

**Request:**
```http
DELETE /users/1
```

**Response (204 No Content):**
```
(empty body)
```

**Response (404 Not Found):**
```json
{
  "error": "User not found"
}
```

## Data Model

### User Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | integer | - | Unique identifier (auto-generated) |
| `first_name` | string | Yes | User's first name (1-255 characters) |
| `last_name` | string | Yes | User's last name (1-255 characters) |
| `gender` | string | Yes | User's gender (`"male"` or `"female"`) |
| `birthdate` | string | Yes | User's birth date (ISO 8601 format: `YYYY-MM-DD`) |
| `inserted_at` | string | - | Creation timestamp (ISO 8601 format) |
| `updated_at` | string | - | Last update timestamp (ISO 8601 format) |

### Validation Rules

- **first_name**: Required, 1-255 characters, whitespace is trimmed
- **last_name**: Required, 1-255 characters, whitespace is trimmed
- **gender**: Required, must be either `"male"` or `"female"`
- **birthdate**: Required, must be a valid date in `YYYY-MM-DD` format

## Example Usage

### cURL Examples

**List all users:**
```bash
curl -X GET http://localhost:4000/users \
  -H "Accept: application/json"
```

**Get specific user:**
```bash
curl -X GET http://localhost:4000/users/1 \
  -H "Accept: application/json"
```

**Create new user:**
```bash
curl -X POST http://localhost:4000/users \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "first_name": "Jan",
      "last_name": "Kowalski",
      "gender": "male",
      "birthdate": "1990-01-15"
    }
  }'
```

**Update user:**
```bash
curl -X PUT http://localhost:4000/users/1 \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "first_name": "Anna",
      "last_name": "Nowak",
      "gender": "female",
      "birthdate": "1985-05-20"
    }
  }'
```

**Delete user:**
```bash
curl -X DELETE http://localhost:4000/users/1
```

### JavaScript/Fetch Examples

**List all users:**
```javascript
const response = await fetch('/users', {
  headers: {
    'Accept': 'application/json'
  }
});
const data = await response.json();
console.log(data.data); // Array of users
```

**Create new user:**
```javascript
const response = await fetch('/users', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    user: {
      first_name: 'Jan',
      last_name: 'Kowalski',
      gender: 'male',
      birthdate: '1990-01-15'
    }
  })
});

if (response.ok) {
  const data = await response.json();
  console.log('Created user:', data.data);
} else {
  const error = await response.json();
  console.error('Error:', error);
}
```

## Error Handling

All error responses follow a consistent format:

```json
{
  "error": "Error message",
  "details": {
    "field_name": ["validation error message"]
  }
}
```

### HTTP Status Codes

- `200 OK` - Successful GET, PUT requests
- `201 Created` - Successful POST request
- `204 No Content` - Successful DELETE request
- `400 Bad Request` - Invalid request format
- `404 Not Found` - Resource not found
- `422 Unprocessable Entity` - Validation errors

## Testing the API

You can test the API using the provided examples or by running the test suite:

```bash
# Run all user controller tests
mix test test/api_web/controllers/user_controller_test.exs

# Run all tests
mix test
```

## Future Enhancements

The current API provides basic CRUD operations. Future versions may include:

- Filtering by name, gender, or birth date range
- Sorting by any field (ascending/descending)
- Pagination with limit and offset
- Search functionality
- Bulk operations

These features are planned but not yet implemented in the current version.