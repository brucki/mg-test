<?php

namespace App\Model;

use Symfony\Component\Validator\Constraints as Assert;

/**
 * User Data Transfer Object
 * 
 * Represents a user entity from the Phoenix API
 */
class User
{
    public ?int $id = null;

    #[Assert\NotBlank(message: 'First name is required')]
    #[Assert\Length(
        min: 2,
        max: 50,
        minMessage: 'First name must be at least {{ limit }} characters long',
        maxMessage: 'First name cannot be longer than {{ limit }} characters'
    )]
    public string $firstName = '';

    #[Assert\NotBlank(message: 'Last name is required')]
    #[Assert\Length(
        min: 2,
        max: 50,
        minMessage: 'Last name must be at least {{ limit }} characters long',
        maxMessage: 'Last name cannot be longer than {{ limit }} characters'
    )]
    public string $lastName = '';

    #[Assert\NotBlank(message: 'Gender is required')]
    #[Assert\Choice(
        choices: ['male', 'female'],
        message: 'Gender must be either "male" or "female"'
    )]
    public string $gender = '';

    #[Assert\NotBlank(message: 'Birth date is required')]
    #[Assert\Type(\DateTimeInterface::class)]
    #[Assert\LessThan(
        'today',
        message: 'Birth date must be in the past'
    )]
    public ?\DateTimeInterface $birthdate = null;

    public ?\DateTimeInterface $insertedAt = null;

    public ?\DateTimeInterface $updatedAt = null;

    /**
     * Create User from API response data
     */
    public static function fromApiData(array $data): self
    {
        $user = new self();
        $user->id = $data['id'] ?? null;
        $user->firstName = $data['first_name'] ?? '';
        $user->lastName = $data['last_name'] ?? '';
        $user->gender = $data['gender'] ?? '';

        if (isset($data['birthdate'])) {
            $user->birthdate = new \DateTime($data['birthdate']);
        }

        if (isset($data['inserted_at'])) {
            $user->insertedAt = new \DateTime($data['inserted_at']);
        }

        if (isset($data['updated_at'])) {
            $user->updatedAt = new \DateTime($data['updated_at']);
        }

        return $user;
    }

    /**
     * Convert User to API request data
     */
    public function toApiData(): array
    {
        $data = [
            'first_name' => $this->firstName,
            'last_name' => $this->lastName,
            'gender' => $this->gender,
        ];

        if ($this->birthdate) {
            $data['birthdate'] = $this->birthdate->format('Y-m-d');
        }

        return $data;
    }

    /**
     * Get full name
     */
    public function getFullName(): string
    {
        return trim($this->firstName . ' ' . $this->lastName);
    }

    /**
     * Get formatted birth date
     */
    public function getFormattedBirthdate(): ?string
    {
        return $this->birthdate?->format('Y-m-d');
    }

    /**
     * Get formatted inserted at date
     */
    public function getFormattedInsertedAt(): ?string
    {
        return $this->insertedAt?->format('Y-m-d H:i:s');
    }

    /**
     * Get formatted updated at date
     */
    public function getFormattedUpdatedAt(): ?string
    {
        return $this->updatedAt?->format('Y-m-d H:i:s');
    }

    /**
     * Get age based on birth date
     */
    public function getAge(): ?int
    {
        if (!$this->birthdate) {
            return null;
        }

        return $this->birthdate->diff(new \DateTime())->y;
    }

    /**
     * Get gender display label
     */
    public function getGenderLabel(): string
    {
        return match ($this->gender) {
            'male' => 'Male',
            'female' => 'Female',
            default => ucfirst($this->gender)
        };
    }
}
