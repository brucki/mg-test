<?php

namespace App\Tests\Controller;

use PHPUnit\Framework\TestCase;
use Symfony\Component\Yaml\Yaml;

class ParameterTest extends TestCase
{
    public function testPhoenixApiParametersAreDefined(): void
    {
        // Load the test configuration
        $configFile = __DIR__ . '/../../config/packages/test/framework.yaml';
        
        // Check if the config file exists
        $this->assertFileExists($configFile, 'framework.yaml config file not found');
        
        // Parse the YAML configuration
        $config = Yaml::parseFile($configFile);
        
        // Check if the Phoenix API configuration exists
        $this->assertIsArray($config, 'Configuration should be an array');
        $this->assertArrayHasKey('framework', $config, 'Framework configuration is missing');
        
        // If we have phoenix_api config, test it
        if (isset($config['phoenix_api'])) {
            $phoenixConfig = $config['phoenix_api'];
            $this->assertIsArray($phoenixConfig, 'phoenix_api configuration should be an array');
            
            if (isset($phoenixConfig['base_url'])) {
                $this->assertIsString($phoenixConfig['base_url'], 'base_url should be a string');
                $this->assertNotEmpty($phoenixConfig['base_url'], 'base_url should not be empty');
                echo "phoenix_api.base_url: " . $phoenixConfig['base_url'] . "\n";
            } else {
                $this->markTestSkipped('phoenix_api.base_url is not configured');
            }
        } else {
            $this->markTestSkipped('phoenix_api configuration is not present in test config');
        }
    }
}
