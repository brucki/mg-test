<?php

namespace App\Form;

use Symfony\Component\Form\AbstractType;
use Symfony\Component\Form\Extension\Core\Type\ChoiceType;
use Symfony\Component\Form\Extension\Core\Type\DateType;
use Symfony\Component\Form\Extension\Core\Type\ResetType;
use Symfony\Component\Form\Extension\Core\Type\SubmitType;
use Symfony\Component\Form\Extension\Core\Type\TextType;
use Symfony\Component\Form\FormBuilderInterface;
use Symfony\Component\OptionsResolver\OptionsResolver;

class UserFilterType extends AbstractType
{
    public function buildForm(FormBuilderInterface $builder, array $options): void
    {
        $builder
            ->add('firstName', TextType::class, [
                'label' => 'Imię',
                'required' => false,
                'attr' => [
                    'class' => 'form-control',
                    'placeholder' => 'Filtruj po imieniu',
                ],
            ])
            ->add('lastName', TextType::class, [
                'label' => 'Nazwisko',
                'required' => false,
                'attr' => [
                    'class' => 'form-control',
                    'placeholder' => 'Filtruj po nazwisku',
                ],
            ])
            ->add('gender', ChoiceType::class, [
                'label' => 'Płeć',
                'choices' => [
                    'Wszystkie' => '',
                    'Mężczyzna' => 'male',
                    'Kobieta' => 'female',
                ],
                'required' => false,
                'attr' => [
                    'class' => 'form-select',
                ],
            ])
            ->add('birthdateFrom', DateType::class, [
                'label' => 'Data urodzenia od',
                'widget' => 'single_text',
                'format' => 'yyyy-MM-dd',
                'html5' => true,
                'required' => false,
                'attr' => [
                    'class' => 'form-control',
                    'max' => (new \DateTime())->format('Y-m-d'),
                ],
            ])
            ->add('birthdateTo', DateType::class, [
                'label' => 'Data urodzenia do',
                'widget' => 'single_text',
                'format' => 'yyyy-MM-dd',
                'html5' => true,
                'required' => false,
                'attr' => [
                    'class' => 'form-control',
                    'max' => (new \DateTime())->format('Y-m-d'),
                ],
            ])
            ->add('filter', SubmitType::class, [
                'label' => 'Filtruj',
                'attr' => [
                    'class' => 'btn btn-primary',
                ],
            ])
            ->add('reset', ResetType::class, [
                'label' => 'Wyczyść filtry',
                'attr' => [
                    'class' => 'btn btn-outline-secondary',
                    'onclick' => 'window.location.href="' . $options['reset_route'] . '"',
                ],
            ]);
    }

    public function configureOptions(OptionsResolver $resolver): void
    {
        $resolver->setDefaults([
            'method' => 'GET',
            'csrf_protection' => false,
            'reset_route' => null,
        ]);
    }

    public function getBlockPrefix(): string
    {
        return ''; // Remove the form name prefix from query parameters
    }
}
