<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

class DefaultController extends AbstractController
{
    #[Route('/', name: 'app_home')]
    public function index(): Response
    {
        return new Response('<h1>Welcome to Symfony 6!</h1><p>Application is running on port 8000</p>');
    }

    #[Route('/health', name: 'app_health')]
    public function health(): JsonResponse
    {
        return new JsonResponse([
            'status' => 'healthy',
            'timestamp' => date('Y-m-d H:i:s'),
            'version' => 'Symfony 6.4'
        ]);
    }

    #[Route('/api/test', name: 'app_api_test')]
    public function apiTest(): JsonResponse
    {
        return new JsonResponse([
            'message' => 'API is working!',
            'framework' => 'Symfony 6.4',
            'php_version' => PHP_VERSION,
            'timestamp' => date('c')
        ]);
    }
}
