<?php

namespace App\Controller;

use App\Form\UserType;
use App\Model\User;
use App\Service\UserApiService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/users', name: 'user_')]
class UserController extends AbstractController
{
    private UserApiService $userApiService;

    public function __construct(UserApiService $userApiService)
    {
        $this->userApiService = $userApiService;
    }

    #[Route('/', name: 'index', methods: ['GET'])]
    public function index(Request $request): Response
    {
        // For AJAX requests, return JSON data directly from the Phoenix API
        if ($request->isXmlHttpRequest()) {
            try {
                $users = $this->userApiService->getAllUsers();
                return $this->json($users);
            } catch (\Exception $e) {
                return $this->json([
                    'success' => false,
                    'error' => 'Wystąpił błąd podczas pobierania danych użytkowników',
                    'details' => $e->getMessage()
                ], 500);
            }
        }

        // For regular requests, render the template with empty data
        return $this->render('user/index.html.twig', [
            'current_page' => 'users',
            'title' => 'Zarządzanie użytkownikami',
            'success_message' => $request->query->get('success') ? 'Operacja zakończona pomyślnie' : null,
        ]);
    }

    #[Route('/new', name: 'new', methods: ['GET'])]
    public function new(): Response
    {
        $user = new User();
        $form = $this->createForm(UserType::class, $user);

        return $this->render('user/form.html.twig', [
            'form' => $form->createView(),
            'title' => 'Dodaj nowego użytkownika',
            'current_page' => 'users',
        ]);
    }

    #[Route('/{id}', name: 'show', methods: ['GET'], requirements: ['id' => '\d+'])]
    public function show(int $id): Response
    {
        // Only pass the user ID to the template
        // The template will handle loading the user data via AJAX
        return $this->render('user/show.html.twig', [
            'userId' => $id,
            'current_page' => 'users',
        ]);
    }

    #[Route('/{id}/edit', name: 'edit', methods: ['GET', 'POST'], requirements: ['id' => '\d+'])]
    public function edit(Request $request, int $id): Response
    {
        // Just render the template without fetching user data
        // The frontend will load the user data via AJAX
        return $this->render('user/edit.html.twig', [
            'user_id' => $id,
            'current_page' => 'users',
            'title' => 'Edytuj użytkownika'
        ]);
    }
}
