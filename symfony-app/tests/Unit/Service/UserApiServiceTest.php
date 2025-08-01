<?php

namespace App\Tests\Unit\Service;

use App\Model\User;
use App\Service\UserApiService;
use App\Exception\ApiConnectionException;
use App\Exception\ApiNotFoundException;
use App\Exception\ApiValidationException;
use PHPUnit\Framework\MockObject\MockObject;
use PHPUnit\Framework\TestCase;
use Symfony\Component\DependencyInjection\ParameterBag\ParameterBagInterface;
use Symfony\Component\HttpClient\Exception\ClientException;
use Symfony\Component\HttpClient\Exception\ServerException;
use Symfony\Component\HttpClient\Exception\RedirectionException;
use Symfony\Component\HttpClient\Exception\TransportException;
use Symfony\Component\HttpClient\MockHttpClient;
use Symfony\Component\HttpClient\Response\MockResponse;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Contracts\HttpClient\HttpClientInterface;

class UserApiServiceTest extends TestCase
{
    private UserApiService $userApiService;
    private ParameterBagInterface|MockObject $parameterBagMock;

    protected function setUp(): void
    {
        $this->parameterBagMock = $this->createMock(ParameterBagInterface::class);
        
        // Configure default parameters
        $this->parameterBagMock->method('get')
            ->willReturnMap([
                ['phoenix_api.base_url', 'http://example.com'],
                ['phoenix_api.timeout', 30.0],
                ['phoenix_api.retry_attempts', 3],
            ]);
    }
    
    private function createUserApiService(iterable $responses = []): UserApiService
    {
        $httpClient = new MockHttpClient($responses, 'http://example.com');
        return new UserApiService($httpClient, $this->parameterBagMock);
    }

    public function testGetAllUsersSuccess(): void
    {
        $responseData = [
            'data' => [
                [
                    'id' => 1,
                    'first_name' => 'John',
                    'last_name' => 'Doe',
                    'gender' => 'male',
                    'birthdate' => '1990-01-01',
                    'inserted_at' => '2023-01-01T00:00:00+00:00',
                ],
                [
                    'id' => 2,
                    'first_name' => 'Jane',
                    'last_name' => 'Doe',
                    'gender' => 'female',
                    'birthdate' => '1992-02-02',
                    'inserted_at' => '2023-01-02T00:00:00+00:00',
                ]
            ]
        ];

        $mockResponse = new MockResponse(json_encode($responseData));
        $service = $this->createUserApiService([$mockResponse]);

        $users = $service->getAllUsers();

        $this->assertCount(2, $users);
        $this->assertInstanceOf(User::class, $users[0]);
        $this->assertEquals('John', $users[0]->firstName);
        $this->assertEquals('Jane', $users[1]->firstName);
        
        // Verify the request was made correctly
        $this->assertSame('GET', $mockResponse->getRequestMethod());
        $this->assertSame('http://example.com/users', $mockResponse->getRequestUrl());
    }

    public function testGetUserByIdSuccess(): void
    {
        $responseData = [
            'data' => [
                'id' => 1,
                'first_name' => 'John',
                'last_name' => 'Doe',
                'gender' => 'male',
                'birthdate' => '1990-01-01',
                'inserted_at' => '2023-01-01T00:00:00+00:00',
            ]
        ];

        $mockResponse = new MockResponse(json_encode($responseData));
        $service = $this->createUserApiService([$mockResponse]);

        $user = $service->getUserById(1);

        $this->assertInstanceOf(User::class, $user);
        $this->assertEquals(1, $user->id);
        $this->assertEquals('John', $user->firstName);
        $this->assertEquals('Doe', $user->lastName);
        
        // Verify the request was made correctly
        $this->assertSame('GET', $mockResponse->getRequestMethod());
        $this->assertSame('http://example.com/users/1', $mockResponse->getRequestUrl());
    }

    public function testCreateUserSuccess(): void
    {
        $responseData = [
            'data' => [
                'id' => 1,
                'first_name' => 'John',
                'last_name' => 'Doe',
                'gender' => 'male',
                'birthdate' => '1990-01-01',
                'inserted_at' => '2023-01-01T00:00:00+00:00',
                'updated_at' => null
            ]
        ];

        $mockResponse = new MockResponse(json_encode($responseData));
        $service = $this->createUserApiService([$mockResponse]);

        $user = new User();
        $user->firstName = 'John';
        $user->lastName = 'Doe';
        $user->gender = 'male';
        $user->birthdate = new \DateTime('1990-01-01');

        $createdUser = $service->createUser($user);

        $this->assertInstanceOf(User::class, $createdUser);
        $this->assertEquals(1, $createdUser->id);
        $this->assertEquals('John', $createdUser->firstName);
        
        // Verify the request was made correctly
        $this->assertSame('POST', $mockResponse->getRequestMethod());
        $this->assertSame('http://example.com/users', $mockResponse->getRequestUrl());
        
        // Verify the request body
        $requestData = json_decode($mockResponse->getRequestOptions()['body'], true);
        $this->assertEquals('John', $requestData['first_name']);
        $this->assertEquals('Doe', $requestData['last_name']);
        $this->assertEquals('male', $requestData['gender']);
        $this->assertEquals('1990-01-01', $requestData['birthdate']);
    }

    public function testUpdateUserSuccess(): void
    {
        $responseData = [
            'data' => [
                'id' => 1,
                'first_name' => 'John Updated',
                'last_name' => 'Doe',
                'gender' => 'male',
                'birthdate' => '1990-01-01',
                'inserted_at' => '2023-01-01T00:00:00+00:00',
                'updated_at' => '2023-01-02T00:00:00+00:00',
            ]
        ];

        $mockResponse = new MockResponse(json_encode($responseData));
        $service = $this->createUserApiService([$mockResponse]);

        $user = new User();
        $user->id = 1;
        $user->firstName = 'John Updated';
        $user->lastName = 'Doe';
        $user->gender = 'male';
        $user->birthdate = new \DateTime('1990-01-01');

        $updatedUser = $service->updateUser($user);

        $this->assertInstanceOf(User::class, $updatedUser);
        $this->assertEquals(1, $updatedUser->id);
        $this->assertEquals('John Updated', $updatedUser->firstName);
        
        // Verify the request was made correctly
        $this->assertSame('PUT', $mockResponse->getRequestMethod());
        $this->assertSame('http://example.com/users/1', $mockResponse->getRequestUrl());
        
        // Verify the request body
        $requestData = json_decode($mockResponse->getRequestOptions()['body'], true);
        $this->assertEquals('John Updated', $requestData['first_name']);
        $this->assertEquals('Doe', $requestData['last_name']);
        $this->assertEquals('male', $requestData['gender']);
        $this->assertEquals('1990-01-01', $requestData['birthdate']);
    }

    public function testDeleteUserSuccess(): void
    {
        $mockResponse = new MockResponse('', ['http_code' => Response::HTTP_NO_CONTENT]);
        $service = $this->createUserApiService([$mockResponse]);

        $service->deleteUser(1);
        
        // Verify the request was made correctly
        $this->assertSame('DELETE', $mockResponse->getRequestMethod());
        $this->assertSame('http://example.com/users/1', $mockResponse->getRequestUrl());
    }

    public function testGetUserByIdNotFound(): void
    {
        $mockResponse = new MockResponse(
            json_encode(['message' => 'User not found']),
            ['http_code' => Response::HTTP_NOT_FOUND]
        );
        
        $service = $this->createUserApiService([$mockResponse]);

        $this->expectException(ApiNotFoundException::class);
        $this->expectExceptionMessage('User not found');

        $service->getUserById(999);
        
        // Verify the request was made correctly
        $this->assertSame('GET', $mockResponse->getRequestMethod());
        $this->assertSame('http://example.com/users/999', $mockResponse->getRequestUrl());
    }

    public function testCreateUserValidationError(): void
    {
        $errors = [
            'first_name' => ['This value should not be blank.'],
            'last_name' => ['This value should not be blank.']
        ];

        $mockResponse = new MockResponse(
            json_encode([
                'message' => 'Validation failed',
                'errors' => $errors
            ]),
            ['http_code' => Response::HTTP_UNPROCESSABLE_ENTITY]
        );
        
        $service = $this->createUserApiService([$mockResponse]);

        $this->expectException(ApiValidationException::class);
        $this->expectExceptionMessage('Validation failed');

        $user = new User(); // Empty user will cause validation errors
        $service->createUser($user);
        
        // Verify the request was made correctly
        $this->assertSame('POST', $mockResponse->getRequestMethod());
        $this->assertSame('http://example.com/users', $mockResponse->getRequestUrl());
    }

    public function testConnectionErrorWithRetry(): void
    {
        // Create a mock HTTP client that throws a TransportException
        $httpClient = $this->createMock(HttpClientInterface::class);
        
        // Configure the mock to throw a TransportException on request
        $httpClient->method('request')
            ->willThrowException(new TransportException('Connection refused'));
        
        // Create a mock ParameterBag for the service with all required parameters
        $params = $this->createMock(ParameterBagInterface::class);
        $params->method('get')
            ->willReturnMap([
                ['app.phoenix_api.base_url', 'http://example.com/api'],
                ['app.phoenix_api.timeout', 30],
                ['app.phoenix_api.retry_attempts', 3],
                ['app.phoenix_api.retry_delay', 100]
            ]);
        
        // Create the service with our mock client and params
        $service = new UserApiService($httpClient, $params);

        $this->expectException(ApiConnectionException::class);
        $this->expectExceptionMessage('Could not connect to the API: Connection refused');

        $service->getAllUsers();
    }

    public function testInvalidResponseFormat(): void
    {
        $mockResponse = new MockResponse(
            json_encode(['invalid' => 'format']),
            ['http_code' => Response::HTTP_OK]
        );
        
        $service = $this->createUserApiService([$mockResponse]);

        $this->expectException(ApiConnectionException::class);
        $this->expectExceptionMessage('Invalid response format from API');

        $service->getAllUsers();
        
        // Verify the request was made correctly
        $this->assertSame('GET', $mockResponse->getRequestMethod());
        $this->assertSame('http://example.com/users', $mockResponse->getRequestUrl());
    }

    public function testServerError(): void
    {
        $mockResponse = new MockResponse(
            json_encode(['message' => 'Internal server error']),
            ['http_code' => Response::HTTP_INTERNAL_SERVER_ERROR]
        );
        
        $service = $this->createUserApiService([$mockResponse]);

        $this->expectException(ApiConnectionException::class);
        $this->expectExceptionMessage('API request failed with status 500: Internal server error');

        $service->getAllUsers();
        
        // Verify the request was made correctly
        $this->assertSame('GET', $mockResponse->getRequestMethod());
        $this->assertSame('http://example.com/users', $mockResponse->getRequestUrl());
    }
}
