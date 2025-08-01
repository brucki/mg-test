<?php

namespace App\Form;

use App\Model\User;
use Symfony\Component\Form\AbstractType;
use Symfony\Component\Form\Extension\Core\Type\ChoiceType;
use Symfony\Component\Form\Extension\Core\Type\DateType;
use Symfony\Component\Form\Extension\Core\Type\SubmitType;
use Symfony\Component\Form\Extension\Core\Type\TextType;
use Symfony\Component\Form\FormBuilderInterface;
use Symfony\Component\OptionsResolver\OptionsResolver;
use Symfony\Component\Validator\Constraints as Assert;

class UserType extends AbstractType
{
    public function buildForm(FormBuilderInterface $builder, array $options): void
    {
        $builder
            ->add('firstName', TextType::class, [
                'label' => 'Imię',
                'constraints' => [
                    new Assert\NotBlank(['message' => 'Proszę podać imię.']),
                    new Assert\Length([
                        'min' => 2,
                        'max' => 50,
                        'minMessage' => 'Imię musi mieć przynajmniej {{ limit }} znaki.',
                        'maxMessage' => 'Imię nie może być dłuższe niż {{ limit }} znaków.',
                    ]),
                ],
                'attr' => [
                    'class' => 'form-control',
                    'placeholder' => 'Wprowadź imię',
                ],
            ])
            ->add('lastName', TextType::class, [
                'label' => 'Nazwisko',
                'constraints' => [
                    new Assert\NotBlank(['message' => 'Proszę podać nazwisko.']),
                    new Assert\Length([
                        'min' => 2,
                        'max' => 50,
                        'minMessage' => 'Nazwisko musi mieć przynajmniej {{ limit }} znaki.',
                        'maxMessage' => 'Nazwisko nie może być dłuższe niż {{ limit }} znaków.',
                    ]),
                ],
                'attr' => [
                    'class' => 'form-control',
                    'placeholder' => 'Wprowadź nazwisko',
                ],
            ])
            ->add('gender', ChoiceType::class, [
                'label' => 'Płeć',
                'choices' => [
                    'Mężczyzna' => 'male',
                    'Kobieta' => 'female',
                ],
                'expanded' => true,
                'multiple' => false,
                'constraints' => [
                    new Assert\NotBlank(['message' => 'Proszę wybrać płeć.']),
                    new Assert\Choice([
                        'choices' => ['male', 'female'],
                        'message' => 'Wybierz poprawną płeć.',
                    ]),
                ],
            ])
            ->add('birthdate', DateType::class, [
                'label' => 'Data urodzenia',
                'widget' => 'single_text',
                'format' => 'yyyy-MM-dd',
                'html5' => true,
                'constraints' => [
                    new Assert\NotBlank(['message' => 'Proszę podać datę urodzenia.']),
                    new Assert\LessThan([
                        'value' => 'today',
                        'message' => 'Data urodzenia musi być z przeszłości.',
                    ]),
                ],
                'attr' => [
                    'class' => 'form-control',
                    'max' => (new \DateTime())->format('Y-m-d'),
                ],
            ])
            ;
    }

    public function configureOptions(OptionsResolver $resolver): void
    {
        $resolver->setDefaults([
            'data_class' => User::class,
            'csrf_protection' => true,
            'csrf_field_name' => '_token',
            'csrf_token_id'   => 'user_item',
        ]);
    }
}
