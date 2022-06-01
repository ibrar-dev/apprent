import axios from 'axios';
import store from './store';

const actions = {
  fetchBankAccounts() {
    axios.get('/api/bank_accounts').then(r => {
      store.dispatch({
        type: 'SET_BANK_ACCOUNTS',
        bankAccounts: r.data
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
  fetchAccounts() {
    axios.get('/api/accounts').then(r => {
      store.dispatch({
        type: 'SET_ACCOUNTS',
        accounts: r.data.filter(a => a.is_cash)
      });
    });
  },
  deleteBankAccount(params) {
    if (params.id) {
      const promise = axios.delete('/api/bank_accounts/' + params.id);
      promise.then(actions.fetchBankAccounts);
      return promise;
    }
    const {bankAccounts} = store.getState();
    const newAccounts = bankAccounts.filter(ba => ba !== params);
    store.dispatch({
      type: 'SET_BANK_ACCOUNTS',
      bankAccounts: newAccounts
    })
  },
  newBankAccount() {
    const {bankAccounts} = store.getState();
    bankAccounts.unshift({name: ''});
    store.dispatch({
      type: 'SET_BANK_ACCOUNTS',
      bankAccounts: [...bankAccounts]
    })
  },
  saveBankAccount(params) {
    return params.id ? actions.updateBankAccount(params) : actions.createBankAccount(params);
  },
  createBankAccount(params) {
    const promise = axios.post('/api/bank_accounts', {bank_account: params});
    promise.then(actions.fetchBankAccounts);
    return promise;
  },
  updateBankAccount(params) {
    const promise = axios.patch('/api/bank_accounts/' + params.id, {bank_account: params});
    promise.then(actions.fetchBankAccounts);
    return promise;
  }
};

export default actions;