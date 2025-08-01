import { Controller } from '@hotwired/stimulus';
import { createApp } from 'vue';
import UserTable from '../vue/components/UserTable.vue';

export default class extends Controller {
    connect() {
        this.app = createApp(UserTable, {
            apiUrl: this.apiUrlValue || '/users'
        });
        this.app.mount(this.element);
    }

    disconnect() {
        this.app.unmount();
    }

    static values = {
        apiUrl: { type: String, default: '/users' }
    }
}
