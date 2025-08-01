import { Controller } from '@hotwired/stimulus';
import { createApp } from 'vue';
import UserTable from '../vue/components/UserTable.vue';

console.log('UserTableController loaded');

export default class extends Controller {
    static values = {
        apiUrl: { type: String, default: '/users' }
    }

    connect() {
        console.log('UserTableController connected');

        this.app = createApp(UserTable, {
            apiUrl: this.apiUrlValue
        });

        // Mount the Vue app to the controller's element
        this.app.mount(this.element);
    }

    disconnect() {
        if (this.app) {
            this.app.unmount();
            this.app = null;
        }
    }
}
