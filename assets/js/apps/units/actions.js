import axios from 'axios';
import store from "./store"
import setLoading from '../../components/loading';
import snackbar from '../../components/snackbar';

const actions = {
  fetchUnits() {
    const {property} = store.getState();
    if (!property) return;
    actions.setSkeleton(true);
    const promise = axios.get(`/api/units?property_id=${property.id}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_UNITS',
        units: r.data
      });
      actions.setSkeleton(false);
    });
    promise.catch(() => {
      snackbar({
        message: 'Unable to get units',
        args: {type: 'error'}
      });
      actions.setSkeleton(false);
    })
    // const {id} = store.getState().property;
    // const unit = store.getState().unit || {};
    // if (!id && !unit.property_id) return;
    // setLoading(true);
    // const promise = axios.get('/api/units?property_id=' + (id || unit.property_id));
    // promise.then(r => {
    //   store.dispatch({
    //     type: 'SET_UNITS',
    //     units: r.data
    //   });
    //   setLoading(false);
    // });
    // return promise;
  },
  fetchUnit(id) {
    setLoading(true);
    const promise = axios.get('/api/units/' + id);
    promise.then(r => {
      store.dispatch({
        type: 'VIEW_UNIT',
        unit: r.data
      });
      setLoading(false);
    });
    return promise;
  },
  fetchFeatures() {
    const promise = axios.get('/api/features');
    promise.then(r => {
      store.dispatch({
        type: 'SET_FEATURES',
        unitTypes: r.data
      });
    });
    return promise;
  },
  fetchProperties() {
    axios.get('/api/property_meta').then(r => {
      store.dispatch({
        type: 'SET_PROPERTIES',
        properties: r.data
      });
      const {property} = store.getState();
      if (!property) actions.viewProperty(r.data[0]);
    })
  },
  fetchFloorPlans() {
    axios.get('/api/floor_plans').then(r => {
      store.dispatch({
        type: 'SET_FLOOR_PLANS',
        floorPlans: r.data
      });
    })
  },
  viewProperty(property) {
    store.dispatch({
      type: 'SET_PROPERTY',
      property
    });
    actions.viewUnit(null);
    actions.fetchUnits();
  },
  viewUnit(unit) {
    store.dispatch({
      type: 'VIEW_UNIT',
      unit
    });
    return unit;
  },
  refresh() {
    actions.fetchUnits().then((r) => {
      let unit = null;
      const currUnit = store.getState().unit;
      if (currUnit) {
        r.data.some(u => u.id === currUnit.id ? unit = u : null);
        actions.viewUnit(unit);
      }
    })
  },
  createUnit(params) {
    const promise = axios.post('/api/units/', {unit: params});
    promise.then(r => {
      snackbar({
        message: 'Unit Successfully added',
        args: {type: 'success'}
      });
      actions.fetchUnits();
    })
    promise.catch(r => {
      snackbar({
        message: 'Error Adding Unit',
        args: {type: 'error'}
      });
      actions.fetchUnits();
    })
    return promise;
  },
  updateUnit(params) {
    const promise = axios.patch('/api/units/' + params.id, {unit: params});
    promise.then(() => actions.refresh());
    return promise;
  },
  deleteUnit(id) {
    const promise = axios.delete(`/api/units/${id}`);
    promise.then(actions.fetchUnits);
    return promise;
  },
  updatePrices(floor_plans) {
    const promise = axios.post("/api/market_rents", {floor_plans});
    promise.then(() => {
      actions.fetchUnits();
      actions.fetchFloorPlans();
    });
    return promise;
  },
  setSkeleton(value) {
    store.dispatch({
      type: 'SET_SKELETON',
      skeleton: value
    })
  }
};

export default actions
