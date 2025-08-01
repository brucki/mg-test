<?php

namespace App\Tests\Model;

use App\Model\User;
use PHPUnit\Framework\TestCase;
use Symfony\Component\Validator\Validation;
use Symfony\Component\Validator\Validator\ValidatorInterface;

class UserTest extends TestCase
{
    private ValidatorInterface $validator;

    protected function setUp(): void
    {
        $this->validator = Validation::createValidatorBuilder()
            ->enableAttributeMapping()
            ->getValidator();
    }

    public function testFromApiData(): void
    {
        $apiData = [
            'id' => 1,
            'first_name' => 'Jan',
            'last_name' => 'Kowalski',
            'gender' => 'male',
            'birthdate' => '1990-01-15',
            'inserted_at' => '2024-01-15T10:30:00Z',
            'updated_at' => '2024-01-15T10:30:00Z'
        ];

        $user = User::fromApiData($apiData);

        $this->assertEquals(1, $user->id);
        $this->assertEquals('Jan', $user->firstName);
        $this->assertEquals('Kowalski', $user->lastName);
        $this->assertEquals('male', $user->gender);
        $this->assertEquals('1990-01-15', $user->birthdate->format('Y-m-d'));
        $this->assertEquals('2024-01-15T10:30:00+00:00', $user->insertedAt->format('c'));
        $this->assertEquals('2024-01-15T10:30:00+00:00', $user->updatedAt->format('c'));
    }

    public function testFromApiDataWithMissingFields(): void
    {
        $apiData = [
            'first_name' => 'Anna',
            'last_name' => 'Nowak'
        ];

        $user = User::fromApiData($apiData);

        $this->assertNull($user->id);
        $this->assertEquals('Anna', $user->firstName);
        $this->assertEquals('Nowak', $user->lastName);
        $this->assertEquals('', $user->gender);
        $this->assertNull($user->birthdate);
        $this->assertNull($user->insertedAt);
        $this->assertNull($user->updatedAt);
    }

    public function testToApiData(): void
    {
        $user = new User();
        $user->firstName = 'Jan';
        $user->lastName = 'Kowalski';
        $user->gender = 'male';
        $user->birthdate = new \DateTime('1990-01-15');

        $apiData = $user->toApiData();

        $expected = [
            'first_name' => 'Jan',
            'last_name' => 'Kowalski',
            'gender' => 'male',
            'birthdate' => '1990-01-15'
        ];

        $this->assertEquals($expected, $apiData);
    }

    public function testToApiDataWithoutBirthdate(): void
    {
        $user = new User();
        $user->firstName = 'Anna';
        $user->lastName = 'Nowak';
        $user->gender = 'female';

        $apiData = $user->toApiData();

        $expected = [
            'first_name' => 'Anna',
            'last_name' => 'Nowak',
            'gender' => 'female'
        ];

        $this->assertEquals($expected, $apiData);
    }

    public function testGetFullName(): void
    {
        $user = new User();
        $user->firstName = 'Jan';
        $user->lastName = 'Kowalski';

        $this->assertEquals('Jan Kowalski', $user->getFullName());
    }

    public function testGetFullNameWithEmptyFields(): void
    {
        $user = new User();
        $user->firstName = 'Jan';
        $user->lastName = '';

        $this->assertEquals('Jan', $user->getFullName());
    }

    public function testGetFormattedBirthdate(): void
    {
        $user = new User();
        $user->birthdate = new \DateTime('1990-01-15');

        $this->assertEquals('1990-01-15', $user->getFormattedBirthdate());
    }

    public function testGetFormattedBirthdateWithNull(): void
    {
        $user = new User();
        $user->birthdate = null;

        $this->assertNull($user->getFormattedBirthdate());
    }

    public function testGetAge(): void
    {
        $user = new User();
        $user->birthdate = new \DateTime('1990-01-15');

        $age = $user->getAge();
        $expectedAge = (new \DateTime())->diff(new \DateTime('1990-01-15'))->y;

        $this->assertEquals($expectedAge, $age);
    }

    public function testGetAgeWithNullBirthdate(): void
    {
        $user = new User();
        $user->birthdate = null;

        $this->assertNull($user->getAge());
    }

    public function testGetGenderLabel(): void
    {
        $user = new User();

        $user->gender = 'male';
        $this->assertEquals('Male', $user->getGenderLabel());

        $user->gender = 'female';
        $this->assertEquals('Female', $user->getGenderLabel());

        $user->gender = 'other';
        $this->assertEquals('Other', $user->getGenderLabel());
    }

    public function testValidationWithValidData(): void
    {
        $user = new User();
        $user->firstName = 'Jan';
        $user->lastName = 'Kowalski';
        $user->gender = 'male';
        $user->birthdate = new \DateTime('1990-01-15');

        $violations = $this->validator->validate($user);

        $this->assertCount(0, $violations);
    }

    public function testValidationWithEmptyFirstName(): void
    {
        $user = new User();
        $user->firstName = '';
        $user->lastName = 'Kowalski';
        $user->gender = 'male';
        $user->birthdate = new \DateTime('1990-01-15');

        $violations = $this->validator->validate($user);

        // Get all violation messages for easier debugging
        $messages = [];
        foreach ($violations as $violation) {
            $messages[] = $violation->getMessage();
        }
        
        // Check that we have at least one violation and it's the expected one
        $this->assertGreaterThanOrEqual(1, count($violations), 'Expected at least one validation violation for empty first name');
        $this->assertContains('First name is required', $messages, 'Expected validation message for empty first name');
    }

    public function testValidationWithShortFirstName(): void
    {
        $user = new User();
        $user->firstName = 'J';
        $user->lastName = 'Kowalski';
        $user->gender = 'male';
        $user->birthdate = new \DateTime('1990-01-15');

        $violations = $this->validator->validate($user);

        $this->assertCount(1, $violations, 'Expected exactly one validation violation for short first name');
        $this->assertStringContainsString('must be at least 2 characters long', (string) $violations->get(0)->getMessage());
    }

    public function testValidationWithLongFirstName(): void
    {
        $user = new User();
        $user->firstName = str_repeat('a', 51);
        $user->lastName = 'Kowalski';
        $user->gender = 'male';
        $user->birthdate = new \DateTime('1990-01-15');

        $violations = $this->validator->validate($user);

        $this->assertCount(1, $violations, 'Expected exactly one validation violation for long first name');
        $this->assertStringContainsString('cannot be longer than 50 characters', (string) $violations->get(0)->getMessage());
    }

    public function testValidationWithInvalidGender(): void
    {
        $user = new User();
        $user->firstName = 'Jan';
        $user->lastName = 'Kowalski';
        $user->gender = 'invalid';
        $user->birthdate = new \DateTime('1990-01-15');

        $violations = $this->validator->validate($user);

        $this->assertCount(1, $violations);
        $this->assertEquals('Gender must be either "male" or "female"', $violations[0]->getMessage());
    }

    public function testValidationWithFutureBirthdate(): void
    {
        $user = new User();
        $user->firstName = 'Jan';
        $user->lastName = 'Kowalski';
        $user->gender = 'male';
        $user->birthdate = new \DateTime('+1 day');

        $violations = $this->validator->validate($user);

        $this->assertCount(1, $violations);
        $this->assertEquals('Birth date must be in the past', $violations[0]->getMessage());
    }

    public function testValidationWithNullBirthdate(): void
    {
        $user = new User();
        $user->firstName = 'Jan';
        $user->lastName = 'Kowalski';
        $user->gender = 'male';
        $user->birthdate = null;

        $violations = $this->validator->validate($user);

        $this->assertCount(1, $violations);
        $this->assertEquals('Birth date is required', $violations[0]->getMessage());
    }
}
