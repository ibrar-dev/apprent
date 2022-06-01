import axios from 'axios';
import store from "./store";
import snackbar from "../../components/snackbar";

const actions = {
  fetchClosings() {
    axios.get('/api/closings').then(r => {
      store.dispatch({
        type: 'SET_CLOSINGS',
        closings: r.data
      })
    })
  },
  fetchProperties() {
    axios.get('/api/property_meta').then(r => {
      store.dispatch({
        type: 'SET_PROPERTIES',
        properties: r.data
      })
    })
  },
  selectProperty(property) {
    store.dispatch({
      type: 'SET_PROPERTY',
      property
    })
  },
  createClosing(params) {
    const promise = axios.post('/api/closings/', {closing: params});
    promise.then(actions.fetchClosings).catch(r => {
      snackbar({args: {type: 'error'}, message: r.response.data.error});
    });
    return promise;
  },
  deleteClosing(params) {
    const promise = axios.delete('/api/closings/' + params.id);
    promise.then(actions.fetchClosings);
    return promise;
  }
};

export default actions
