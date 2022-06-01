import axios from 'axios';
import store from "./store"
import setLoading from '../../components/loading';
import snackbar from '../../components/snackbar';

const actions = {
  createAdminDocs(params) {
    return axios.post('/api/admin_documents', params);
  },
  deletePropertyDocs(id) {
    return axios.delete(`api/admin_documents/${id}`);
  },
  fetchPropertyDocuments(property_id) {
    const promise = axios.get(`/api/property_admin_documents?property_ids=${property_id}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_ADMIN_DOCUMENTS',
        adminDocuments: r.data
      })
    });
    return promise;
  },
  fetchProperties() {
    const promise = axios.get('/api/properties?min=true');
    promise.then(r => {
        store.dispatch({
          type: 'SET_PROPERTIES',
          properties: r.data
        });
        actions.fetchProperty();
      }
    );
    return promise
  },
  fetchProperty(prop) {
    const {property, properties} = store.getState();
    const id = (prop || property || properties[0] || {}).id;
    if (!id) return {};
    const promise = axios.get('/api/properties/' + id);
    promise.then(r => {
      store.dispatch({
        type: 'SET_PROPERTY',
        property: r.data
      });
      actions.fetchBankAccounts(id);
      actions.fetchOpenings();
      actions.fetchClosures();
      actions.fetchIntegrations();
      actions.fetchFeatures();
      actions.fetchFloorPlans();
      actions.fetchUnits();
      actions.fetchChargeCodes();
    });
    return promise;
  },
  fetchAccounts() {
    axios.get('/api/accounts').then(r => {
      store.dispatch({
        type: 'SET_ACCOUNTS',
        accounts: r.data
      });
    });
  },
  createProperty(property) {
    const promise = axios.post('/api/properties', property);
    promise.then(actions.fetchProperty);
    return promise;
  },
  updateProperty(property) {
    const promise = axios.patch(`/api/properties/${property.id}`, {property});
    promise.then(() => {
      snackbar({
        message: "Property Successfully Updated",
        args: {type: "success"}
      });
      actions.fetchProperty()
    });
    return promise;
  },
  uploadCSV(file, fileType, property) {
    const data = new FormData();
    data.append('import[file]', file);
    data.append('import[type]', fileType);
    data.append('import[property]', property);
    setLoading(true);
    const promise = axios.post('/api/imports', data);
    promise.then(setLoading.bind(null, false));
    return promise;
  },
  saveRegister(params) {
    let promise;
    if (params.id) {
      promise = axios.patch('/api/registers/' + params.id, {register: params});
    } else {
      promise = axios.post('/api/registers', {register: params});
    }
    promise.then(() => actions.fetchProperty());
    return promise;
  },
  deleteRegister(register) {
    const promise = axios.delete(`/api/registers/${register.id}`);
    promise.then(() => actions.fetchProperty());
    return promise;
  },
  fetchPhoneLines() {
    setLoading(true);
    const propertyId = store.getState().property.id;
    axios.get('/api/phone_lines?property_id=' + propertyId).then(r => {
      store.dispatch({
        type: 'SET_PHONE_LINES',
        phoneLines: r.data
      });
      setLoading(false);
    })
  },
  createPhoneLine(params) {
    setLoading(true);
    axios.post('/api/phone_lines', {phone_line: params}).then(() => {
      actions.fetchPhoneLines();
    }).then(() => {
      snackbar({
        message: 'New Phone Line Added',
        args: {type: "success"}
      })
    }).catch(r => {
      setLoading(false);
      snackbar({
        message: r.response.data.error,
        args: {type: "error"}
      })
    })
  },
  fetchBankAccounts(propertyId) {
    axios.get(`/api/bank_accounts?property_id=${propertyId}`).then(r => {
      store.dispatch({
        type: 'SET_BANK_ACCOUNTS',
        bankAccounts: r.data
      })
    })
  },
  deletePhoneLine(params) {
    setLoading(true);
    axios.delete('/api/phone_lines/' + params.id).then(() => {
      actions.fetchPhoneLines();
    })
  },
  getHtmlTemplatePreview(html) {
    setLoading(true);
    const promise = axios.post(`/api/applications?rental_verification_form_preview`, {
      html,
      property_id: store.getState().property.id
    });
    promise.finally(() => {
      setLoading(false);
    });
    return promise;
  },
  // OPENINGS
  fetchOpenings() {
    const promise = axios.get('/api/openings');
    promise.then(r => {
      store.dispatch({
        type: 'SET_OPENINGS',
        openings: r.data
      });
    });
    return promise;
  },
  fetchClosures() {
    const {property} = store.getState();
    const promise = axios.get(`/api/closures?property_id=${property.id}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_CLOSURES',
        closures: r.data
      })
    });
    promise.catch(() => {
      snackbar({
        message: "Unable to fetch closures",
        args: {type: 'error'}
      });
    })
  },
  createOpening(params) {
    const promise = axios.post('/api/openings', {opening: params});
    promise.then(actions.fetchOpenings);
    return promise;
  },
  updateOpening(params) {
    const promise = axios.patch('/api/openings/' + params.id, {opening: params});
    promise.then(actions.fetchOpenings);
    return promise;
  },
  deleteOpening(params) {
    const promise = axios.delete('/api/openings/' + params.id);
    promise.then(actions.fetchOpenings);
    return promise;
  },
  fetchAffectedShowings(property_id, date) {
    const promise = axios.get(`/api/closures/${property_id}?date=${date}`);
    return promise;
  },
  saveClosure(closure) {
    const promise = axios.post('/api/closures', {closure});
    promise.then(() => {
      snackbar({
        message: 'Closure set and prospects notified',
        args: {type: 'success'}
      });
      actions.fetchClosures();
    })
    promise.catch(e => {
      snackbar({
        message: e.response.data,
        args: {type: 'error'}
      });
    })
  },
  saveClosureAll(closure) {
    const promise = axios.post(`/api/closures?all=true`, {closure});
    promise.then(() => {
      snackbar({
        message: 'Closures set and prospects notified',
        args: {type: 'success'}
      });
      actions.fetchClosures();
    });
    promise.catch(e => {
      snackbar({
        message: e.response.data,
        args: {type: 'error'}
      });
    })
  },
  // INTEGRATIONS
  fetchIntegrations() {
    setLoading(true);
    axios.get('/api/integrations').then(r => {
      store.dispatch({
        type: 'SET_INTEGRATIONS',
        integrations: r.data
      });
      setLoading(false);
    })
  },
  saveProcessor(params) {
    setLoading(true);
    let promise;
    if (params.id) {
      promise = axios.patch('/api/integrations/' + params.id, {processor: params});
    } else {
      promise = axios.post('/api/integrations', {processor: params});
    }
    promise.then(() => {
      snackbar({
        message: 'Integration updated successfully',
        args: {type: 'success'}
      });
      actions.fetchIntegrations();
    }).catch(() => {
      setLoading(false);
      snackbar({
        message: 'Something went wrong',
        args: {type: 'error'}
      })
    });
    return promise;
  },
  createPayscapeAccount(params) {
    setLoading(true);
    const {term, cert, property_id, type, ...create_account} = params;
    const promise = axios.post('/api/integrations', {
      create_account,
      processor: {name: 'Payscape', keys: [cert, term], type, property_id}
    });
    promise.then(() => {
        snackbar({
          message: 'Payscape account created successfully', args: {type: 'success'}
        });
        actions.fetchIntegrations();
      }
    ).catch(e => {
      setLoading(false);
      snackbar({
        message: 'Unable to create account: ' + e.response.data.error, args: {type: 'error'}
      });
    });
    return promise;
  },
  listBlueMoonPropertyIds(processorId) {
    setLoading(true);
    const promise = axios.get(`/api/integrations/${processorId}?bluemoon_id=true`);
    promise.then(() => setLoading(false));
    return promise;
  },
  updateProperty(propertyId, params) {
    setLoading(true);
    const promise = axios.patch(`/api/properties/${propertyId}`, {property: params});
    promise.then(() => {
      snackbar({
        message: "Property Successfully Updated",
        args: {type: "success"}
      });
      setLoading(false);
      const currentProperty = JSON.parse(getCookie("property"));
      setCookie('property', JSON.stringify({...currentProperty, ...params}));
      actions.fetchProperties()
    });
    return promise;
  },
  // FloorPlans
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
  fetchUnits() {
    axios.get('/api/units').then(r => {
      store.dispatch({
        type: 'SET_UNITS',
        units: r.data
      });
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
