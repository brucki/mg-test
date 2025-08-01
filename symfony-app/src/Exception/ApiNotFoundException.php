<?php

namespace App\Exception;

class ApiNotFoundException extends ApiException
{
    public function __construct(string $message = 'The requested resource was not found', \Throwable $previous = null)
    {
        parent::__construct($message, 404, [], $previous);
    }
}
