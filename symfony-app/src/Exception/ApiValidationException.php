<?php

namespace App\Exception;

class ApiValidationException extends ApiException
{
    public function __construct(array $errors = [], string $message = 'Validation failed', \Throwable $previous = null)
    {
        parent::__construct($message, 422, $errors, $previous);
    }
}
