import axios from 'axios';
import store from "./store"

let actions = {
  fetchExports() {
    axios.get('/api/exports').then(r => {
      store.dispatch({
        type: 'SET_EXPORTS',
        exports: r.data,
      });
    });
  },
  updateExport(params) {
    axios.patch(`/api/exports/${params.id}`, {export: params}).then(actions.fetchExports);
  },
  fetchRecipients() {
    return axios.get('/api/export_recipients');
  },
  deleteExport(params) {
    const promise = axios.delete('/api/exports/' + params.id);
    promise.then(actions.fetchExports);
    return promise;
  },
  sendDocument(params) {
    return axios.patch('/api/exports/' + params.id, {send: params});
  },
  createRecipient(params) {
    return axios.post('/api/export_recipients', {recipient: params});
  }
};

export default actions
