import axios from 'axios';
import store from "./store";
import setLoading from '../../components/loading';
import snackbar from '../../components/snackbar';

const actions = {
  fetchFeatures() {
    const promise = axios.get('/api/features');
    promise.then(r => {
      store.dispatch({
        type: 'SET_FEATURES',
        features: r.data
      });
    });
    return promise;
  },
  fetchChargeCodes() {
    const promise = axios.get('/api/charge_codes');
    promise.then(r => {
      store.dispatch({
        type: 'SET_CHARGE_CODES',
        chargeCodes: r.data
      });
    });
  },
  fetchFloorPlans() {
    const promise = axios.get('/api/floor_plans');
    promise.then(r => {
      store.dispatch({
        type: 'SET_FLOOR_PLANS',
        floorPlans: r.data
      });
    });
  },
  fetchProperties() {
    axios.get('/api/property_meta').then(r => {
      store.dispatch({
        type: 'SET_PROPERTIES',
        properties: r.data
      });
    })
  },
  fetchUnits() {
    axios.get('/api/units').then(r => {
      store.dispatch({
        type: 'SET_UNITS',
        units: r.data
      });
    })
  },
  setProperty(property) {
    store.dispatch({
      type: 'SET_PROPERTY',
      property
    })
  },
  addFeature() {
    const {property, features} = store.getState();
    store.dispatch({
      type: 'SET_FEATURES',
      features: [{property_id: property.id, name: 'New Feature', price: 100, units: []}, ...features]
    });
  },
  addFloorPlan() {
    const {property, floorPlans} = store.getState();
    store.dispatch({
      type: 'SET_FLOOR_PLANS',
      floorPlans: [{property_id: property.id, name: 'New Floor Plan', price: 100, feature_ids: [], units: [], charges: []}, ...floorPlans]
    });
  },
  createFeature(params) {
    const promise = axios.post('/api/features/', {feature: params});
    promise.then(actions.fetchFeatures);
    return promise;
  },
  updateFeature(params) {
    const promise = axios.patch('/api/features/' + params.id, {feature: params});
    promise.then(actions.fetchFeatures);
    return promise;
  },
  saveFeature(params) {
    const promise = params.id ? actions.updateFeature(params) : actions.createFeature(params);
    promise.then(() => {

    });
    return promise;
  },
  deleteFeature(params) {
    if (params.id) return axios.delete('/api/features/' + params.id).then(actions.fetchFeatures);
    store.dispatch({
      type: 'SET_FEATURES',
      features: store.getState().features.filter(f => f !== params)
    })
  },
  createFloorPlan(params) {
    const promise = axios.post('/api/floor_plans/', {floor_plan: params});
    promise.then(actions.fetchFloorPlans);
    return promise;
  },
  updateFloorPlan(params) {
    const promise = axios.patch('/api/floor_plans/' + params.id, {floor_plan: params});
    promise.then(actions.fetchFloorPlans);
    return promise;
  },
  saveFloorPlan(params) {
    if (params.id) return actions.updateFloorPlan(params);
    return actions.createFloorPlan(params);
  },
  deleteFloorPlan(params) {
    if (params.id) return axios.delete('/api/floor_plans/' + params.id).then(actions.fetchFloorPlans);
    store.dispatch({
      type: 'SET_FLOOR_PLANS',
      floorPlans: store.getState().floorPlans.filter(f => f !== params)
    })
  },
  setMode(mode) {
    store.dispatch({type: 'SET_MODE', mode});
  },
  // saveDefaultCharge(charge) {
  //   setLoading(true);
  //   const promise = axios.post('/api/default_lease_charges', {charge});
  //   promise.then(() => {
  //     snackbar({
  //       message: 'Default Lease Charge Saved',
  //       args: {type: 'success'}
  //     });
  //     actions.fetchFloorPlans();
  //     setLoading(false);
  //   });
  //   promise.catch(() => {
  //     snackbar({
  //       message: 'Default Lease Charge NOT Saved',
  //       args: {type: 'error'}
  //     });
  //     setLoading(false);
  //   })
  // },
  saveDefaultCharges(newCharges){
    setLoading(true);
    const promise = axios.post('/api/default_lease_charges', {newCharges});
    promise.then(() => {
      snackbar({
        message: 'Default Lease Charge Saved',
        args: {type: 'success'}
      });
      // actions.fetchFloorPlans();
      setLoading(false);
    });
    promise.catch((e) => {
      snackbar({
        message: e.response.data.error,
        args: {type: 'error'}
      });
      setLoading(false);
    })
  },
  updateDefaultCharges(charges){
    const promise = axios.patch(`/api/default_lease_charges`, {charges});
    promise.then(() => {
      snackbar({
        message: 'Default Lease Charge Updated',
        args: {type: 'success'}
      });
      actions.fetchFloorPlans();
    });
    promise.catch(() => {
      snackbar({
        message: 'Default Lease Charge NOT updated',
        args: {type: 'error'}
      });
    });
  },
  // updateDefaultCharge(charge) {
  //   setLoading(true);
  //   const promise = axios.patch(`/api/default_lease_charges/${charge.id}`, {charge});
  //   promise.then(() => {
  //     snackbar({
  //       message: 'Default Lease Charge Updated',
  //       args: {type: 'success'}
  //     });
  //     setLoading(false);
  //   });
  //   promise.catch(() => {
  //     snackbar({
  //       message: 'Default Lease Charge NOT updated',
  //       args: {type: 'error'}
  //     });
  //     setLoading(false);
  //   })
  // },
  cloneCharges(initial_id, target_id) {
    const promise = axios.post(`/api/default_lease_charges?clone`, {floor_plan_id: initial_id, target_floor_plan_id: target_id});
    promise.then(() => {
      actions.fetchFloorPlans();
    });
    promise.catch(() => {
      actions.fetchFloorPlans()
    })
  },
  deleteCharge(charge_id) {
    const promise = axios.delete(`/api/default_lease_charges/${charge_id}`);
    promise.then(() => actions.fetchFloorPlans())
  }
};

export default actions
