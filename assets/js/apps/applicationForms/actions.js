import axios from 'axios';
import moment from "moment";
import store from "./store"
import setLoading from '../../components/loading';
import snackbar from '../../components/snackbar';
import ajaxDownload from "../../utils/ajaxDownload";

let actions = {
  createDocument(params){
    return axios.post('/api/applications', params);
  },
  createMemo(params){
    return axios.post(`/api/applications`, {...params, application_id: params.application_id, memos: true});
  },
  fetchApplications(propertyId, startDate, endDate) {
    if (!startDate) startDate = moment().subtract(30, 'day').format("YYYY-MM-DD");
    if (!endDate) endDate = moment().format("YYYY-MM-DD");
    store.dispatch({
      type: 'SET_APPLICATION',
      application: null
    });
    const property = store.getState().property;
    const promise = axios.get(`/api/applications?property_id=${propertyId || property.id}&start_date=${startDate}&end_date=${endDate}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_APPLICATIONS',
        applications: r.data.applications
      });
      store.dispatch({
        type: 'SET_CREDENTIALS_LIST',
        credentials: r.data.credentials_list
      });
    });
    return promise;
  },
  fetchProperties() {
    const promise = axios.get('/api/property_meta');
    promise.then(r => {
      store.dispatch({
        type: 'SET_PROPERTIES',
        properties: r.data
      });
      const {property} = store.getState();
      if (!property.id) return actions.setProperty(r.data[0]);
      r.data.some(p => {
        if (p.id === property.id) {
          actions.setProperty(p);
          return true;
        }
      });
    })
  },
  fetchApplication(id) {
    const promise = axios.get('/api/applications/' + id);
    promise.then(r => {
      store.dispatch({
        type: 'SET_APPLICATION',
        application: r.data
      });
    });
    return promise;
  },
  fetchLease(applicationId) {
    setLoading(true);
    const promise = axios.get(`/api/application_leases/${applicationId}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_LEASE',
        lease: r.data
      });
      setLoading(false);
    });
    return promise;
  },
  fetchUnits() {
    axios.get('/api/units?rentable=true').then(r => {
      store.dispatch({
        type: 'SET_UNITS',
        units: r.data
      })
    })
  },
  fetchChargeCodes() {
    axios.get('/api/charge_codes').then(r => {
      store.dispatch({
        type: 'SET_CHARGE_CODES',
        chargeCodes: r.data
      });
    });
  },
  fetchAvailableUnits(property_id, startDate) {
    setLoading(true);
    const promise = axios.get(`/api/units/?property_id=${property_id}&start=${startDate}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_AVAILABLE_UNITS',
        availableUnits: r.data
      });
      setLoading(false);
    });
    promise.catch(() => {
      snackbar({
        message: "Unable to fetch available units. Please refresh the page. Sorry about that :(",
        args: {type: "error"}
      });
      setLoading(false);
    });
    return promise;
  },
  updateApplication(params) {
    setLoading(true);
    const promise = axios.patch(`/api/applications/${params.id}?full`, {application: params});
    promise.then(() => {
      actions.fetchApplications();
      setLoading(false)
    });
    return promise;
  },
  updateApplicationStatus(application) {
    setLoading(true);
    const promise = axios.patch(`/api/applications/${application.id}`, {application});
    promise.then(() => {
      actions.fetchApplications();
      setLoading(false)
    });
    return promise;
  },
  forward() {
    store.dispatch({
      type: 'STEP_FORWARD',
      step: 0
    })
  },
  back() {
    store.dispatch({
      type: 'STEP_BACK',
      step: 0
    })
  },
  declineApplication(id, declined_reason) {
    setLoading(true);
    const promise = axios.patch(`/api/applications/${id}`, {declined_reason});
    promise.then(() => {
      actions.fetchApplications();
      setLoading(false);
      snackbar(({
        message: "Declined",
        args: {type: "success"}
      }));
    });
    promise.catch(() => {
      actions.fetchApplications();
      setLoading(false);
      snackbar(({
        message: "Something went wrong declining the applicant",
        args: {type: "error"}
      }));
    });
    return promise;
  },
  approveApplication(id, params) {
    setLoading(true);
    const promise = axios.patch(`/api/applications/${id}`, {approve: params});
    const property = store.getState().property;
    promise.then(() => {
      actions.fetchApplications(property.id);
      setLoading(false);
      snackbar(({
        message: "Approved",
        args: {type: "success"}
      }));
    });
    promise.catch((e) => {
      actions.fetchApplications(property.id);
      setLoading(false);
      snackbar(({
        message: e.response.data.error,
        args: {type: "error"}
      }));
    });
    return promise;
  },
  bypassApproveApplication(id, params) {
    setLoading(true);
    const promise = axios.patch(`/api/applications/${id}`, {bypass: params});
    const property = store.getState().property;
    promise.then(() => {
      actions.fetchApplications(property.id);
      setLoading(false);
      snackbar(({
        message: "Approval Set",
        args: {type: "success"}
      }));
    });
    promise.catch((e) => {
      actions.fetchApplications(property.id);
      setLoading(false);
      snackbar(({
        message: e.response.data.error,
        args: {type: "error"}
      }));
    });
    return promise;
  },
  getPaymentUrl(id) {
    return axios.get(`/api/applications/${id}?payment_url=true`);
  },
  sendPaymentUrl(id) {
    return axios.get(`/api/applications/${id}?payment_url_send=true`)
  },
  submitScreening(applicationId, rent) {
    const promise = axios.post('/api/screenings', {application: {id: applicationId, rent}});
    const property = store.getState().property;
    promise.then(() => actions.fetchApplications(property.id));
    return promise;
  },
  getScreeningStatus(applicationId) {
    const promise = axios.patch('/api/screenings/' + applicationId, {});
    promise.then(actions.fetchApplications);
    return promise;
  },
  updateLease(lease) {
    setLoading(true);
    const promise = axios.patch(`/api/application_leases/${lease.id}`, {lease});
    promise.then(() => {
      actions.fetchLease(lease.application_id);
      snackbar({
        message: 'Lease Updated',
        args: {type: 'success'}
      })
    }).catch((r) => {
      snackbar({
        message: r.response.data.error,
        args: {type: 'error'}
      });
      setLoading(false);
    });
    return promise;
  },
  executeLease(lease) {
    setLoading(true);
    let resolve, reject;
    const promise = new Promise((res, rej) => {
      resolve = res;
      reject = rej;
    });
    axios.patch(`/api/application_leases/${lease.id}`, {lease}).then(() => {
      axios.patch(`/api/application_leases/${lease.application_id}`).then(() => {
        setLoading(false);
        actions.fetchLease(lease.application_id);
        resolve();
      }).catch(r => {
        setLoading(false);
        snackbar({message: r.response.data.error, args: {type: 'error'}});
        reject(r);
      });
    });
    return promise;
  },
  unlockLease(lease) {
    const promise = axios.patch('/api/application_leases/' + lease.id, {unlock: true});
    promise.then(() => {
      actions.fetchLease(lease.application_id);
      snackbar({
        message: 'Lease Unlocked',
        args: {type: 'success'}
      })
    }).catch((r) => {
      snackbar({
        message: r.response.data.error,
        args: {type: 'error'}
      });
      setLoading(false);
    });
    return promise;
  },
  fetchUnitInfo(unit_id) {
    const promise = axios.get(`/api/units/${unit_id}`);
    promise.then(r => {
      actions.setUnitInfo(r.data)
    })
    return promise;
  },
  setUnitInfo(unitInfo){
    store.dispatch({
      type: 'SET_UNIT_INFO',
      unitInfo: unitInfo
    })
  },
  setProperty(property) {
    actions.fetchApplications(property.id).then(r => {
      if(r.data.applications.length > 0 && r.data.applications[0].full === 'true') {
        actions.fetchUnits();
        actions.fetchChargeCodes();
      }
    });
    store.dispatch({
      type: 'SET_PROPERTY',
      property
    })
  },
  generateForm(params){
    const {person_id, property_id} = params;
    setLoading(true);
    const promise = axios.post(`/api/applications`, {property_id: property_id, person_id: person_id, rental_verification_form: true});
    promise.catch((e) => {
      snackbar({
        message: e.response.data.error,
        args: {type: 'error'}
      })
    })
    promise.finally(() => {
      setLoading(false);
    });
    return promise;
  }
};


export default actions
