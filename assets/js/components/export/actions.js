import axios from 'axios';

const actions = {
  fetchCategories() {
    return axios.get('/api/exports');
  },
  fetchRecipients() {
    return axios.get('/api/export_recipients');
  },
  createCategory(params) {
    return axios.post('/api/exports', {category: params});
  },
  createRecipient(params) {
    return axios.post('/api/export_recipients', {recipient: params});
  }
};

export default actions;