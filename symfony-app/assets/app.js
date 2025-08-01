import * as Vue from 'vue';
// Expose Vue globally for inline scripts in Twig templates
if (typeof window !== 'undefined') {
    window.Vue = Vue;
}
import { registerVueControllerComponents } from '@symfony/ux-vue';
import './bootstrap.js';

// any CSS you import will output into a single css file (app.css in this case)
import './styles/app.css';

// Log Vue version for debugging
console.log('Vue version:', Vue.version);

// Configure Vue in production mode for better performance
const isProduction = process.env.NODE_ENV === 'production';

// Log environment
console.log(`Running in ${isProduction ? 'production' : 'development'} mode`);

// Only set global config if not using Vue 3's createApp
if (Vue.config) {
    if (isProduction) {
        Vue.config.devtools = false;
        Vue.config.productionTip = false;
    }
} else if (Vue.createApp) {
    // Vue 3 - config is per-app, not global
    console.log('Using Vue 3 - config will be set per app instance');
} else {
    console.warn('Unknown Vue version - could not set configuration');
}

try {
    // Register Vue components
    const context = require.context('./vue/controllers', true, /\.vue$/);
    registerVueControllerComponents(context);
    console.log('Vue components registered');
} catch (error) {
    console.error('Failed to register Vue components:', error);
}