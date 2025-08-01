<?php

namespace App\Exception;

class ApiConnectionException extends ApiException
{
    public function __construct(string $message = 'Could not connect to the API', \Throwable $previous = null)
    {
        parent::__construct($message, 0, [], $previous);
    }
}
