import axios from 'axios';;
import store from "./store";

const actions = {
  fetchDevices() {
    axios.get('/api/devices').then(r => {
      store.dispatch({
        type: 'SET_DEVICES',
        devices: r.data
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
  createDevice(params) {
    const promise = axios.post('/api/devices', {device: params});
    promise.then(actions.fetchDevices);
    return promise;
  },
  updateDevice(params) {
    const promise = axios.patch('/api/devices/' + params.id, {device: params});
    promise.then(actions.fetchDevices);
    return promise;
  },
  deleteDevice(params) {
    const promise = axios.delete('/api/devices/' + params.id);
    promise.then(actions.fetchDevices);
    return promise;
  }
};

export default actions;
