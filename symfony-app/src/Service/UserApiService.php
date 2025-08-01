<?php

namespace App\Service;

use App\Model\User;
use App\Exception\ApiConnectionException;
use App\Exception\ApiValidationException;
use App\Exception\ApiNotFoundException;
use Symfony\Component\HttpClient\HttpClient;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpClient\Exception\TransportException;
use Symfony\Component\HttpClient\Exception\ClientException;
use Symfony\Component\HttpClient\Exception\ServerException;
use Symfony\Component\HttpClient\Exception\RedirectionException;
use Symfony\Contracts\HttpClient\HttpClientInterface;
use Symfony\Component\DependencyInjection\ParameterBag\ParameterBagInterface;

class UserApiService
{
    private HttpClientInterface $httpClient;
    private string $apiBaseUrl;
    private int $apiTimeout;
    private int $apiRetryAttempts;

    public function __construct(
        HttpClientInterface $httpClient,
        ParameterBagInterface $params
    ) {
        $this->httpClient = $httpClient;
        
        // Get parameters with null coalescing to default values
        $baseUrl = $params->get('phoenix_api.base_url') ?? '';
        $this->apiBaseUrl = rtrim($baseUrl, '/');
        $this->apiTimeout = (int) ($params->get('phoenix_api.timeout') ?? 10);
        $this->apiRetryAttempts = (int) ($params->get('phoenix_api.retry_attempts') ?? 3);
        
        // Log parameter values for debugging
        error_log(sprintf(
            'UserApiService initialized with base_url=%s, timeout=%d, retry_attempts=%d',
            $this->apiBaseUrl,
            $this->apiTimeout,
            $this->apiRetryAttempts
        ));
    }

    /**
     * Get all users from the API
     *
     * @return User[]
     * @throws ApiConnectionException
     */
    public function getAllUsers(): array
    {
        $response = $this->request('GET', '/users');
        
        if (!isset($response['data']) || !is_array($response['data'])) {
            throw new ApiConnectionException('Invalid response format from API');
        }

        return array_map(
            fn(array $userData) => User::fromApiData($userData),
            $response['data']
        );
    }

    /**
     * Get a single user by ID
     *
     * @throws ApiNotFoundException
     * @throws ApiConnectionException
     */
    public function getUserById(int $id): User
    {
        $response = $this->request('GET', "/users/{$id}");

        if (!isset($response['data'])) {
            throw new ApiConnectionException('Invalid response format from API');
        }

        return User::fromApiData($response['data']);
    }

    /**
     * Create a new user
     *
     * @throws ApiValidationException
     * @throws ApiConnectionException
     */
    public function createUser(User $user): User
    {
        $response = $this->request('POST', '/users', $user->toApiData());

        if (!isset($response['data'])) {
            throw new ApiConnectionException('Invalid response format from API');
        }

        return User::fromApiData($response['data']);
    }

    /**
     * Update an existing user
     *
     * @throws ApiValidationException
     * @throws ApiNotFoundException
     * @throws ApiConnectionException
     */
    public function updateUser(User $user): User
    {
        if ($user->id === null) {
            throw new \InvalidArgumentException('Cannot update user without ID');
        }

        $response = $this->request(
            'PUT',
            "/users/{$user->id}",
            $user->toApiData()
        );

        if (!isset($response['data'])) {
            throw new ApiConnectionException('Invalid response format from API');
        }

        return User::fromApiData($response['data']);
    }

    /**
     * Delete a user by ID
     *
     * @throws ApiNotFoundException
     * @throws ApiConnectionException
     */
    public function deleteUser(int $id): void
    {
        $this->request('DELETE', "/users/{$id}");
    }

    /**
     * Make an HTTP request to the API with retry logic
     *
     * @param string $method HTTP method (GET, POST, PUT, DELETE)
     * @param string $endpoint API endpoint (e.g., '/users')
     * @param array $data Request data (for POST/PUT requests)
     * @return array Decoded JSON response
     * @throws ApiConnectionException
     * @throws ApiValidationException
     * @throws ApiNotFoundException
     */
    private function request(string $method, string $endpoint, array $data = []): array
    {
        // Ensure the endpoint starts with a slash
        $endpoint = '/' . ltrim($endpoint, '/');
        
        // Use the base URL as is, without adding /api
        $baseUrl = rtrim($this->apiBaseUrl, '/');
        $url = $baseUrl . $endpoint;
        $options = [
            'timeout' => $this->apiTimeout,
            'headers' => [
                'Accept' => 'application/json',
                'Content-Type' => 'application/json',
            ],
        ];

        if (in_array($method, ['POST', 'PUT', 'PATCH'], true)) {
            $options['json'] = $data;
        }

        $attempt = 0;
        $lastException = null;

        while ($attempt < $this->apiRetryAttempts) {
            try {
                $response = $this->httpClient->request($method, $url, $options);
                $statusCode = $response->getStatusCode();
                
                // For 204 No Content responses, return an empty array
                if ($statusCode === Response::HTTP_NO_CONTENT) {
                    return [];
                }
                
                // For other responses, try to parse as JSON
                $content = $response->toArray(false);

                if ($statusCode >= 200 && $statusCode < 300) {
                    return $content;
                }

                // Handle error responses
                $message = $content['message'] ?? 'Unknown error';
                $errors = $content['errors'] ?? [];

                switch ($statusCode) {
                    case Response::HTTP_UNPROCESSABLE_ENTITY: // 422
                        throw new ApiValidationException($errors, $message);
                    case Response::HTTP_NOT_FOUND: // 404
                        throw new ApiNotFoundException($message);
                    default:
                        // Create a new exception with the error message
                        $exception = new \RuntimeException(sprintf('API request failed with status %d: %s', $statusCode, $message));
                        throw new ApiConnectionException(
                            $exception->getMessage(),
                            $exception
                        );
                }
            } catch (TransportException $e) {
                $lastException = new ApiConnectionException(
                    'Could not connect to the API: ' . $e->getMessage(),
                    $e  // Pass the original exception as previous
                );
                // Wait before retrying (exponential backoff)
                usleep((2 ** $attempt) * 100000); // 100ms, 200ms, 400ms, etc.
            } catch (ClientException $e) {
                $statusCode = $e->getResponse()->getStatusCode();
                $content = $e->getResponse()->toArray(false);
                $message = $content['message'] ?? $e->getMessage();

                if ($statusCode === Response::HTTP_NOT_FOUND) {
                    throw new ApiNotFoundException($message, 0, $e);
                }
                if ($statusCode === Response::HTTP_UNPROCESSABLE_ENTITY) {
                    throw new ApiValidationException(
                        $content['errors'] ?? [],
                        $message,
                        0,
                        $e
                    );
                }
                throw new ApiConnectionException(
                    sprintf('API request failed with status %d: %s', $statusCode, $message),
                    $e
                );
            } catch (ServerException $e) {
                $lastException = new ApiConnectionException(
                    sprintf('API server error (status %d): %s', 
                        $e->getResponse()->getStatusCode(),
                        $e->getMessage()
                    ),
                    $e
                );
            } catch (RedirectionException $e) {
                $lastException = new ApiConnectionException(
                    'Too many redirects: ' . $e->getMessage(),
                    $e
                );
            } catch (\JsonException $e) {
                throw new ApiConnectionException(
                    'Failed to decode API response: ' . $e->getMessage(),
                    $e  // Pass the original exception as previous
                );
            }

            $attempt++;
        }

        throw $lastException ?? new ApiConnectionException('Unknown error occurred while making API request');
    }
}
