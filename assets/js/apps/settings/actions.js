import store from './store';
import axios from 'axios';
import setLoading from '../../components/loading';

const actions = {
  fetchBanks() {
    setLoading(true);
    axios.get('/api/banks').then(r => {
      store.dispatch({
        type: 'SET_BANKS',
        banks: r.data
      });
      setLoading(false);
    });
  },
  fetchCredentialSets() {
    setLoading(true);
    axios.get('/api/credential_sets').then(r => {
      store.dispatch({
        type: 'SET_CREDENTIAL_SETS',
        credentialSets: r.data
      });
      setLoading(false);
    });
  },
  fetchDamages() {
    setLoading(true);
    axios.get('/api/damages').then(r => {
      store.dispatch({
        type: 'SET_DAMAGES',
        damages: r.data
      });
      setLoading(false);
    });
  },
  fetchAccounts() {
    axios.get('/api/accounts').then(r => {
      store.dispatch({
        type: 'SET_ACCOUNTS',
        accounts: r.data
      });
    });
  },
  fetchMoveOutReasons() {
    setLoading(true);
    axios.get('/api/move_out_reasons').then(r => {
      store.dispatch({
        type: 'SET_MOVE_OUT_REASONS',
        moveOutReasons: r.data
      });
      setLoading(false);
    });
  },
  createBank(params) {
    if (actions.validateRouting(params.routing)) {
      setLoading(true);
      const promise = axios.post('/api/banks', {bank: params});
      promise.then(actions.fetchBanks);
      return promise;
    }
    alert('Routing number is invalid');
  },
  createDamage(params) {
    setLoading(true);
    const promise = axios.post('/api/damages', {damage: params});
    promise.then(actions.fetchDamages);
    return promise;
  },
  createCredentialSet(params) {
    setLoading(true);
    const promise = axios.post('/api/credential_sets', {credential_set: params});
    promise.then(actions.fetchCredentialSets);
    return promise;
  },
  updateCredentialSet(params) {
    setLoading(true);
    const promise = axios.patch('/api/credential_sets/' + params.id, {credential_set: params});
    promise.then(actions.fetchCredentialSets);
    return promise;
  },
  createMoveOutReason(params) {
    setLoading(true);
    const promise = axios.post('/api/move_out_reasons', {move_out_reason: params});
    promise.then(actions.fetchMoveOutReasons);
    return promise;
  },
  updateBank(params) {
    if (actions.validateRouting(params.routing)){
      setLoading(true);
      const promise = axios.patch('/api/banks/' + params.id, {bank: params});
      promise.then(actions.fetchBanks);
      return promise;
    }
    alert('Routing number is invalid');
  },
  updateDamage(params) {
    setLoading(true);
    const promise = axios.patch('/api/damages/' + params.id, {damage: params});
    promise.then(actions.fetchDamages);
    return promise;
  },
  deleteBank(params) {
    setLoading(true);
    const promise = axios.delete('/api/banks/' + params.id);
    promise.then(actions.fetchBanks);
    return promise;
  },
  deleteDamage(params) {
    setLoading(true);
    const promise = axios.delete('/api/damages/' + params.id);
    promise.then(actions.fetchDamages);
    return promise;
  },
  deleteMoveOutReason(params) {
    setLoading(true);
    const promise = axios.delete('/api/move_out_reasons/' + params.id);
    promise.then(actions.fetchMoveOutReasons).catch(r => setLoading(false));
    return promise;
  },
  validateRouting(number) {
    try {
      parseInt(number);
    }
    catch (err) {
      return  false;
    }
    if (number.length !== 9 || number.charAt(0) === '5') return  false;
    //First two digits are between 01-12, 21-32, 61-72, 80
    const validStart = number.substring(0, 2);
    const regexp = /0(?=[1-9])|1(?=[0-2])|2(?=[0-9])|3(?=[0-2])|6(?=[0-9])|7(?=[0-2])|80/;
    if (!validStart.match(regexp)) return  false;
    //ABA Routing Number Checksum
    let n = 0;
    for (let i = 0; i < number.length; i += 3) {
      n += parseInt(number.charAt(i), 10) * 3
        + parseInt(number.charAt(i + 1), 10) * 7 + parseInt(number.charAt(i + 2), 10);
    }
    return !(n === 0 || n % 10 !== 0);
  }
};

export default actions;