import axios from 'axios';
import store from "./store"
import setLoading from "../../components/loading";
import snackbar from "../../components/snackbar";

let actions = {
  fetchPropertiesDocuments(property_ids) {
    return axios.get(`/api/property_admin_documents?property_ids=${property_ids}`).then(r => {
      store.dispatch({
        type: 'SET_ADMIN_DOCUMENTS',
        adminDocuments: r.data
      })
    });
  },
  fetchingData(status) {
    store.dispatch({
      type: 'SET_FETCHING',
      status: status
    })
  },
  fetchDailySnapshot(date) {
    const promise = axios.post('/api/orders', {snapshot: date});
    promise.then(r => {
      store.dispatch({
        type: 'SET_MAINTENANCE_SNAPSHOT',
        stats: r.data
      })
    });
    promise.catch(e => {

    });
  },
  multipleLeases(params) {
    const promise = axios.post('/api/leases?multiple_leases', params);
    promise.then(actions.fetchProperties);
  },
  fetchProperties() {
    setLoading(true);
    const promise = axios.get('/api/properties?min');
    promise.then(r => {
      store.dispatch({
        type: 'SET_PROPERTIES',
        properties: r.data
      });
      const {property} = store.getState();
      if (!property.id) return actions.viewProperty(r.data[0]);
      r.data.some(p => {
        if (p.id === property.id) {
          actions.viewProperty(p);
          return true;
        }
      });
      setLoading(false)
    });
    promise.catch(() => {
      snackbar({
        message: 'Unable to fetch properties',
        args: {type: 'error'}
      })
    })
  },
  viewProperty(property) {
    setLoading(true);
    store.dispatch({
      type: 'SET_PROPERTY',
      property
    });
    actions.fetchingData(true);
    actions.fetchPropertyEvents(property);
    actions.fetchPropertyReport(property);
  },
  fetchPropertyReport(property) {
    const promise = axios.get(`/api/property_report?property_ids=${property.id}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_PROPERTY_REPORT',
        data: r.data
      });
      actions.fetchingData(false);
      setLoading(false);
    });
    promise.catch(() => {
      snackbar({
        message: 'Unable to fetch dashboard',
        args: {type: 'error'}
      })
      setLoading(false);
    });
  },
  fetchPropertyEvents(property) {
    const promise = axios.get(`/api/events?property_id=${property.id}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_EVENTS',
        events: r.data
      })
    })
  },
  updateParts(parts) {
    const promise = axios.patch(`/api/maintenance_parts/0`, {parts: parts});
    promise.then(() => {
      actions.fetchPropertyReport()
      snackbar({
        message: `Parts successfully updated. Please note that this order cannot be assigned until all parts have been delivered`,
        args: {type: "success"}
      })
    }).catch(() => {
      snackbar({
        message: `Parts has NOT been updated. Please make sure all the information is correct. If you are still having problems please contact an IT admin`,
        args: {type: "error"}
      })
    });
    return promise;
  }

};

export default actions
