import axios from 'axios';
import store from "./store"

let actions = {
  fetchMigrations() {
    axios.get('/api/migrations').then(r => {
      store.dispatch({
        type: 'SET_MIGRATIONS',
        migrations: r.data,
      });
    });
  },
  updateMigration(params) {
    axios.patch(`/api/migrations/${params.id}`, {migration: params}).then(actions.fetchMigrations);
  },
  createMigration(params) {
    const promise = axios.post('/api/migrations', {migration: params});
    promise.then(actions.fetchMigrations);
    return promise;
  },
  deleteJob(params) {
    const promise = axios.delete('/api/migrations/' + params.id);
    promise.then(actions.fetchMigrations);
    return promise;
  }
};

export default actions
