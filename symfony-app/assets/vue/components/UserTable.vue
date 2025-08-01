<template>
  <div class="user-table">
    <!-- Loading State -->
    <div v-if="loading" class="text-center my-5">
      <div class="spinner-border text-primary" role="status">
        <span class="visually-hidden">Ładowanie...</span>
      </div>
      <p class="mt-2">Ładowanie listy użytkowników...</p>
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="alert alert-danger">
      <i class="bi bi-exclamation-triangle-fill me-2"></i>
      {{ error }}
      <button type="button" class="btn-close float-end" @click="error = null"></button>
    </div>

    <!-- Empty State -->
    <div v-else-if="users.length === 0" class="alert alert-info">
      <i class="bi bi-info-circle-fill me-2"></i>
      Brak użytkowników do wyświetlenia.
    </div>

    <!-- User Table -->
    <div v-else class="table-responsive">
      <table class="table table-striped table-hover">
        <thead class="table-dark">
          <tr>
            <th>ID</th>
            <th>Imię</th>
            <th>Nazwisko</th>
            <th>Płeć</th>
            <th>Data urodzenia</th>
            <th>Akcje</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="user in users" :key="user.id">
            <td>{{ user.id }}</td>
            <td>{{ user.first_name || '-' }}</td>
            <td>{{ user.last_name || '-' }}</td>
            <td>{{ formatGender(user.gender) }}</td>
            <td>{{ formatDate(user.birthdate) }}</td>
            <td>
              <a :href="`/users/${user.id}/edit`" class="btn btn-sm btn-outline-primary me-1">
                <i class="bi bi-pencil"></i>
              </a>
              <button class="btn btn-sm btn-outline-danger" @click="confirmDelete(user)">
                <i class="bi bi-trash"></i>
              </button>
            </td>
          </tr>
        </tbody>
      </table>
      
      <!-- Pagination -->
      <div v-if="pagination.total_pages > 1" class="d-flex justify-content-between align-items-center mt-3">
        <div class="text-muted">
          Wyświetlono {{ users.length }} z {{ pagination.total_count || users.length }} użytkowników
        </div>
        <nav aria-label="Nawigacja po stronach">
          <ul class="pagination mb-0">
            <li class="page-item" :class="{ 'disabled': pagination.page === 1 }">
              <button class="page-link" @click="changePage(1)" :disabled="pagination.page === 1">
                &laquo;&laquo;
              </button>
            </li>
            <li class="page-item" :class="{ 'disabled': pagination.page === 1 }">
              <button class="page-link" @click="changePage(pagination.page - 1)" :disabled="pagination.page === 1">
                &laquo;
              </button>
            </li>
            <li v-for="page in visiblePages" :key="page" class="page-item" :class="{ 'active': page === pagination.page }">
              <button class="page-link" @click="changePage(page)">
                {{ page }}
              </button>
            </li>
            <li class="page-item" :class="{ 'disabled': pagination.page === pagination.total_pages }">
              <button class="page-link" @click="changePage(pagination.page + 1)" :disabled="pagination.page === pagination.total_pages">
                &raquo;
              </button>
            </li>
            <li class="page-item" :class="{ 'disabled': pagination.page === pagination.total_pages }">
              <button class="page-link" @click="changePage(pagination.total_pages)" :disabled="pagination.page === pagination.total_pages">
                &raquo;&raquo;
              </button>
            </li>
          </ul>
        </nav>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue';

export default {
  name: 'UserTable',
  props: {
    apiUrl: {
      type: String,
      default: 'http://phoenix:4000/users'
    }
  },
  setup(props) {
    const loading = ref(true);
    const error = ref(null);
    const users = ref([]);
    const pagination = ref({
      page: 1,
      per_page: 10,
      total_pages: 1,
      total_count: 0
    });
    const visiblePageCount = 5;

    const visiblePages = computed(() => {
      const pages = [];
      const current = pagination.value.page;
      const total = pagination.value.total_pages;
      const range = Math.floor(visiblePageCount / 2);
      
      let start = Math.max(1, current - range);
      let end = Math.min(total, start + visiblePageCount - 1);
      
      if (end - start + 1 < visiblePageCount) {
        start = Math.max(1, end - visiblePageCount + 1);
      }
      
      for (let i = start; i <= end; i++) {
        pages.push(i);
      }
      
      return pages;
    });

    const fetchUsers = async () => {
      loading.value = true;
      error.value = null;
      
      try {
        const response = await fetch(`${props.apiUrl}?page=${pagination.value.page}&per_page=${pagination.value.per_page}`);
        
        if (!response.ok) {
          throw new Error(`Błąd HTTP: ${response.status}`);
        }
        
        const data = await response.json();
        
        users.value = data.data || [];
        pagination.value = {
          ...pagination.value,
          page: data.meta?.current_page || 1,
          total_pages: data.meta?.total_pages || 1,
          total_count: data.meta?.total || users.value.length
        };
      } catch (err) {
        console.error('Błąd podczas pobierania użytkowników:', err);
        error.value = 'Wystąpił błąd podczas pobierania listy użytkowników. Spróbuj odświeżyć stronę.';
      } finally {
        loading.value = false;
      }
    };
    
    const changePage = (page) => {
      if (page < 1 || page > pagination.value.total_pages || page === pagination.value.page) {
        return;
      }
      
      pagination.value.page = page;
      fetchUsers();
      
      // Scroll to top of the table
      window.scrollTo({
        top: 0,
        behavior: 'smooth'
      });
    };
    
    const formatDate = (dateString) => {
      if (!dateString) return '-';
      return new Date(dateString).toLocaleDateString('pl-PL');
    };
    
    const formatGender = (gender) => {
      if (!gender) return '-';
      return gender === 'male' ? 'Mężczyzna' : 'Kobieta';
    };
    
    const confirmDelete = async (user) => {
      if (confirm(`Czy na pewno chcesz usunąć użytkownika "${user.first_name} ${user.last_name}"?`)) {
        try {
          loading.value = true;
          const response = await fetch(`${props.apiUrl}/${user.id}`, {
            method: 'DELETE',
            headers: {
              'Content-Type': 'application/json',
              'X-Requested-With': 'XMLHttpRequest'
            },
            credentials: 'same-origin'
          });
          
          if (!response.ok) {
            throw new Error(`Błąd HTTP: ${response.status}`);
          }
          
          // Refresh the user list after successful deletion
          await fetchUsers();
          
          // Show success message
          alert('Użytkownik został pomyślnie usunięty.');
        } catch (err) {
          console.error('Błąd podczas usuwania użytkownika:', err);
          error.value = 'Wystąpił błąd podczas usuwania użytkownika. Spróbuj ponownie.';
        } finally {
          loading.value = false;
        }
      }
    };
    
    // Fetch users when component is mounted
    onMounted(() => {
      fetchUsers();
    });
    
    return {
      loading,
      error,
      users,
      pagination,
      visiblePages,
      changePage,
      formatDate,
      formatGender,
      confirmDelete
    };
  }
};
</script>

<style scoped>
.user-table {
  margin: 1rem 0;
}

.page-item.active .page-link {
  background-color: #0d6efd;
  border-color: #0d6efd;
}

.page-link {
  color: #0d6efd;
  cursor: pointer;
}

.page-item.disabled .page-link {
  color: #6c757d;
  pointer-events: none;
}
</style>
