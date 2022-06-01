import axios from 'axios';
import store from './store';
import snackbar from "../../components/snackbar";

const actions = {
  fetchAccounts() {
    axios.get('/api/accounts').then(r => {
      store.dispatch({
        type: 'SET_ACCOUNTS',
        accounts: r.data
      });
    });
  },
  fetchProperties() {
    axios.get('/api/property_meta').then(r => {
      store.dispatch({
        type: 'SET_PROPERTIES',
        properties: r.data
      });
    });
  },
  newAccount(type) {
    const {accounts} = store.getState();
    accounts.unshift({name: '', type});
    store.dispatch({
      type: 'SET_ACCOUNTS',
      accounts: [...accounts]
    })
  },
  removeNew(type) {
    const {accounts} = store.getState();
    const newAccounts = accounts.filter(t => t !== type);
    store.dispatch({
      type: 'SET_ACCOUNTS',
      accounts: newAccounts
    })
  },
  createAccount(params) {
    const promise = axios.post('/api/accounts', {account: params});
    promise.then(() => {
      snackbar({
        message: "Account Created",
        args: {type: 'success'}
      });
      actions.fetchCategories();
    }).catch(e => {
      snackbar({
        message: e.response.data.error,
        args: {type: 'error'}
      });
    });
    return promise;
  },
  updateAccount(params) {
    const promise = axios.patch('/api/accounts/' + params.id, {account: params});
    promise.then(() => {
      snackbar({
        message: "Account Updated",
        args: {type: 'success'}
      });
      actions.fetchCategories();
    }).catch(e => {
      snackbar({
        message: e.response.data.error,
        args: {type: 'error'}
      });
    });
    return promise;
  },
  deleteAccount(params) {
    const promise = axios.delete('/api/accounts/' + params);
    promise.then(() => {
      snackbar({
        message: "Account Deleted",
        args: {type: 'success'}
      });
      actions.fetchCategories();
    });
    promise.catch(e => {
      snackbar({
        message: e.response.data,
        args: {type: 'error'}
      });
    });
    return promise;
  },
  uploadCSV(params) {
    const data = new FormData();
    data.append('property_id', params.property_id);
    data.append('data', params.file);
    return axios.post('/api/accounting_charges', data);
  },
  //CATEGORIES
  fetchCategories() {
    const promise = axios.get(`/api/accounts?categories`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_CATEGORIES',
        categories: r.data
      })
    })
  },
  updateCategory(account_category) {
    const promise = axios.patch(`/api/account_categories/${account_category.id}`, {account_category});
    promise.then(() => {
      snackbar({
        message: "Account Category Updated",
        args: {type: 'success'}
      });
    }).catch(e => {
      snackbar({
        message: e.response.data.error,
        args: {type: 'error'}
      });
    }).finally(actions.fetchCategories);
  },
  saveCategory(account_category) {
    const promise = axios.post('/api/account_categories', {account_category});
    promise.then(() => {
      snackbar({
        message: "Account Category Created",
        args: {type: 'success'}
      });
      actions.fetchCategories();
    }).catch(e => {
      snackbar({
        message: e.response.data.error,
        args: {type: 'error'}
      });
    });
    return promise;
  },
  deleteCategory(category_id) {
    const promise = axios.delete('/api/account_categories/' + category_id);
    promise.then(() => {
      snackbar({
        message: "Account Deleted",
        args: {type: 'success'}
      });
      actions.fetchCategories();
    }).catch(e => {
      snackbar({
        message: e.response.data.error,
        args: {type: 'error'}
      });
    });
  }
};

export default actions;