import axios from 'axios';
import store from './store';
import setLoading from '../../components/loading';
import snackbar from '../../components/snackbar';

const actions = {
  fetchProperties() {
    axios.get('/api/property_meta').then(r => {
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
    })
  },
  viewProperty(property) {
    setLoading(true);
    store.dispatch({
      type: 'SET_PROPERTY',
      property
    });
    actions.fetchPeriods(property);
  },
  fetchPeriods(property) {
    axios.get(`/api/lease_periods?property_id=${property.id}`).then(r => {
      setLoading(false);
      store.dispatch({
        type: 'SET_BATCH_PERIODS',
        periods: r.data
      });
      actions.fetchReport(property);
    }).catch(() => {
      setLoading(false)
    });
  },
  fetchReport(property) {
    axios.get(`/api/lease_renewals?report&property_id=${property.id}`).then(r => {
      store.dispatch({
        type: 'SET_REPORT',
        report: r.data
      });
    });
  },
  savePeriod(period) {
    setLoading(true);
    const promise = axios.post('/api/lease_periods', {period});
    promise.then(() => {
      actions.fetchPeriods(store.getState().property);
      snackbar({
        message: 'New Period Created',
        args: {type: 'success'}
      });
    }).finally(() => {
      setLoading(false);
    });
    return promise;
  },
  updateLeases(lease_ids){
    const promise = axios.post('/api/leases', {lease_ids: lease_ids, params: {no_renewal: true}});
    promise.then(() => {
      snackbar({
        message: "Leases Updated",
        args: {type: 'success'}
      })
      actions.fetchPeriods(store.getState().property);
    });
    return promise;
  },
  updatePeriod(id, params) {
    setLoading(true);
    const promise = axios.patch(`/api/lease_periods/${id}`, params);
    promise.then(() => {
      snackbar({
        message: 'Parameters Saved',
        args: {type: 'success'}
      });
      actions.fetchPeriods(store.getState().property);
    }).catch(() => {
      snackbar({
        message: 'Unable to update period',
        args: {type: 'error'}
      })
    }).finally(() => {
      setLoading(false);
    });
    return promise;
  },
  deletePeriod(periodId) {
    axios.delete(`/api/lease_periods/${periodId}`).then(() => {
      actions.fetchPeriods(store.getState().property);
      snackbar({
        message: 'Period deleted',
        args: {type: 'success'}
      });
    })
  },
  checkValidDates(startDate, endDate) {
    const {property} = store.getState();
    const req = `/api/lease_renewals?valid_dates=true&start_date=${startDate}&end_date=${endDate}&property_id=${property.id}`;
    axios.get(req).then(r => {
      store.dispatch({
        type: 'SET_VALIDATION',
        validation: {loading: false, validDates: r.data.valid, leases: r.data.leases}
      });
    });
  },
  deletePackage(id, property) {
    const promise = axios.delete(`/api/lease_packages/${id}`);
    promise.then(() => {
      actions.viewProperty(property)
    })
  },
  addNote(add_note) {
    setLoading(true);
    const promise = axios.patch(`/api/lease_renewals/true`, {add_note});
    promise.then(() => {
      actions.fetchPeriods(store.getState().property);
      setLoading(false)
    }).catch(() => {
      setLoading(false)
    });
    return promise;
  },
  createCustomPackage(params) {
    setLoading(true);
    axios.post(`/api/custom_packages/`, {custom_package: params}).then(() => {
      actions.fetchPeriods(store.getState().property);
    });
  },
  updateCustomPackage(params) {
    setLoading(true);
    axios.patch(`/api/custom_packages/${params.id}`, {custom_package: params}).then(() => {
      actions.fetchPeriods(store.getState().property);
    });
  }
};

export default actions;