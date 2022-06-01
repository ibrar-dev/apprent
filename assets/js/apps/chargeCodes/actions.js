import axios from 'axios';
import store from './store';

const actions = {
  fetchChargeCodes() {
    axios.get('/api/charge_codes').then(r => {
      store.dispatch({
        type: 'SET_CHARGE_CODES',
        chargeCodes: r.data
      });
    });
  },
  deleteChargeCode(params) {
    const promise = axios.delete('/api/charge_codes/' + params.id);
    promise.then(actions.fetchChargeCodes);
    return promise;
  },
  createAccount(params) {
    const promise = axios.post('/api/charge_codes', {charge_code: params});
    promise.then(actions.fetchChargeCodes);
    return promise;
  },
  updateAccount(params) {
    const promise = axios.patch('/api/charge_codes/' + params.id, {charge_code: params});
    promise.then(actions.fetchChargeCodes);
    return promise;
  }
};

export default actions;