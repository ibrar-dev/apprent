import axios from 'axios';
import store from "./store"

let actions = {
  fetchProperties() {
    axios.get('/api/properties').then(r => {
      store.dispatch({
        type: 'SET_PROPERTIES',
        properties: r.data
      })
    })
  },
  fetchEntities() {
    axios.get('/api/entities').then(r => {
      store.dispatch({
        type: 'SET_ENTITIES',
        entities: r.data
      })
    })
  },
  newEntity() {
    axios.post('/api/entities', {name: 'New Entity'}).then(actions.fetchEntities());
  },
  updateEntity(id, params) {
    const promise = axios.patch('/api/entities/' + id, {entity: params});
    promise.then(actions.fetchEntities);
    return promise;
  },
  attachProperty(id, propertyId) {
    axios.patch('/api/entities/' + id, {property_id: propertyId, attach: true}).then(actions.fetchEntities);
  },
  detachProperty(id, propertyId) {
    axios.patch('/api/entities/' + id, {property_id: propertyId, detach: true}).then(actions.fetchEntities);
  }
};

export default actions
