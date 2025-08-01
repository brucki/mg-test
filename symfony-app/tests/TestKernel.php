<?php

namespace App\Tests;

use Symfony\Component\HttpKernel\Kernel;
use Symfony\Component\Config\Loader\LoaderInterface;

class TestKernel extends Kernel
{
    public function registerBundles(): iterable
    {
        $bundles = parent::registerBundles();
        
        // Add any test bundles here if needed
        
        return $bundles;
    }
    
    public function registerContainerConfiguration(LoaderInterface $loader)
    {
        $loader->load($this->getProjectDir().'/config/packages/test/framework.yaml');
        $loader->load($this->getProjectDir().'/config/services_test.yaml');
        
        // Load test-specific configuration
        $loader->load(function ($container) {
            $container->loadFromExtension('framework', [
                'test' => true,
                'session' => [
                    'storage_id' => 'session.storage.mock_file',
                ],
            ]);
        });
    }
    
    public function getCacheDir(): string
    {
        return $this->getProjectDir().'/var/cache/test';
    }
    
    public function getLogDir(): string
    {
        return $this->getProjectDir().'/var/log/test';
    }
}
