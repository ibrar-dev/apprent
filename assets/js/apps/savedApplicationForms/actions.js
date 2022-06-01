import axios from 'axios';
import store from "./store"

let actions = {
  fetchProperties() {
    const promise = axios.get('/api/property_meta');
    promise.then(r => {
      store.dispatch({type: 'SET_PROPERTIES', properties: r.data});
      return actions.setProperty(r.data[0]);
    })
  },
  setProperty(property) {
    store.dispatch({type: 'SET_PROPERTY', property})
    actions.fetchApplications(property.id)
  },
  fetchApplications(property_id) {
    const promise = axios.get('/api/saved_forms?property_id=' + property_id);
    promise.then(r => {
      store.dispatch({type: 'SET_APPLICATIONS', applications: r.data.applications});
    });
    return promise;
  },
};

export default actions
