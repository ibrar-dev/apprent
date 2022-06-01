import store from './store';
import axios from 'axios';;

const actions = {
  fetchPrizes() {
    axios.get('/api/prizes').then(r => {
      store.dispatch({
        type: 'SET_PRIZES',
        prizes: r.data.prizes
      });
    });
  },
  fetchTypes() {
    axios.get('/api/reward_types').then(r => {
      store.dispatch({
        type: 'SET_TYPES',
        types: r.data.types
      });
    });
  },
  saveType(params) {
    return params.id ? actions.updateType(params) : actions.createType(params);
  },
  createType(params) {
    const formData = new FormData();
    Object.keys(params).forEach(p => params[p] && formData.append(`type[${p}]`, params[p]));
    formData.append(`type[active]`, params.active);
    const promise = axios.post('/api/reward_types', formData);
    promise.then(actions.fetchTypes);
    return promise;
  },
  updateType(params) {
    const formData = new FormData();
    Object.keys(params).forEach(p => params[p] && formData.append(`type[${p}]`, params[p]));
    formData.append(`type[active]`, params.active);
    const promise = axios.patch('/api/reward_types/' + params.id, formData);
    promise.then(actions.fetchTypes);
    return promise;
  },
  savePrize(params) {
    return params.id ? actions.updatePrize(params) : actions.createPrize(params);
  },
  deleteType(type) {
    const promise = axios.delete('/api/reward_types/' + type.id);
    promise.then(actions.fetchTypes);
    return promise;
  },
  createPrize(params) {
    const formData = new FormData();
    Object.keys(params).forEach(p => params[p] && formData.append(`reward[${p}]`, params[p]));
    const promise = axios.post('/api/prizes', formData);
    promise.then(actions.fetchPrizes);
    return promise;
  },
  updatePrize(params) {
    const formData = new FormData();
    Object.keys(params).forEach(p => params[p] && formData.append(`reward[${p}]`, params[p]));
    const promise = axios.patch('/api/prizes/' + params.id, formData);
    promise.then(actions.fetchPrizes);
    return promise;
  },
  deletePrize(prize) {
    const promise = axios.delete('/api/prizes/' + prize.id);
    promise.then(actions.fetchPrizes);
    return promise;
  },
};

export default actions;
