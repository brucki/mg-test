<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Symfony\Component\HttpKernel\Log\DebugLoggerInterface;
use Psr\Log\LoggerInterface;

class ErrorController extends AbstractController
{
    public function show(
        \Throwable $exception,
        ?DebugLoggerInterface $logger = null,
        ?LoggerInterface $loggerService = null
    ): Response {
        $statusCode = Response::HTTP_INTERNAL_SERVER_ERROR;
        $statusText = 'Wystąpił błąd';
        
        if ($exception instanceof HttpExceptionInterface) {
            $statusCode = $exception->getStatusCode();
            $statusText = $exception->getMessage() ?: Response::$statusTexts[$statusCode] ?? 'Wystąpił błąd';
        }
        
        // Log the error
        if ($loggerService) {
            $context = [
                'exception' => $exception,
                'status_code' => $statusCode,
                'status_text' => $statusText,
                'trace' => $exception->getTraceAsString(),
            ];
            
            $loggerService->error($exception->getMessage(), $context);
        }
        
        // Custom error pages based on status code
        $template = sprintf('error/%s.html.twig', $statusCode);
        
        if (!$this->get('twig')->getLoader()->exists($template)) {
            $template = 'error/error.html.twig';
        }
        
        return $this->render($template, [
            'status_code' => $statusCode,
            'status_text' => $statusText,
            'exception' => $exception,
            'is_safe' => $this->getParameter('kernel.debug'),
        ], new Response('', $statusCode));
    }
    
    public function preview(int $code): Response
    {
        // This is only available in dev/test environment
        $this->denyAccessUnlessGranted('ROLE_ADMIN');
        
        $statusText = Response::$statusTexts[$code] ?? 'Unknown Error';
        $exception = new HttpException($code, $statusText);
        
        return $this->show($exception);
    }
}
