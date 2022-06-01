import axios from 'axios';
import store from './store';

const actions = {
  fetchPayees() {
    axios.get('/api/payees').then(r => {
      store.dispatch({
        type: 'SET_PAYEES',
        payees: r.data
      });
    });
  },
  deletePayee(params) {
    const promise = axios.delete('/api/payees/' + params.id);
    promise.then(actions.fetchPayees);
    return promise;
  },
  createPayee(params) {
    const promise = axios.post('/api/payees', {payee: params});
    promise.then(actions.fetchPayees);
    return promise;
  },
  updatePayee(params) {
    const promise = axios.patch('/api/payees/' + params.id, {payee: params});
    promise.then(actions.fetchPayees);
    return promise;
  },
  savePayee(params) {
    const func = params.id ? 'updatePayee' : 'createPayee';
    return actions[func](params);
  },
  setPayee(payee) {
    store.dispatch({
      type: 'SET_PAYEE',
      payee
    });
  }
};

export default actions;
