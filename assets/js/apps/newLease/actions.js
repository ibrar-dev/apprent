import axios from 'axios';
import store from './store';
import setLoading from '../../components/loading';
import snackbar from '../../components/snackbar';

const actions = {
  fetchLeaseParams() {
    setLoading(true);
    axios.get(`/api/leases/${BASE_LEASE_ID}`).then(r => {
      store.dispatch({
        type: 'SET_LEASE',
        lease: r.data
      });
      actions.fetchAvailableUnits(r.data.property_id, r.data.start_date);
      actions.fetchLeasePackages(r.data.property_id).then(lp => {
        actions.setDefaultLeaseCharges(lp.data.default_lease_charges);
      });
      actions.setRent(r.data.rent);
      setLoading(false);
    })
  },
  fetchLeasePackages(property_id){
    const promise = axios.get(`/api/lease_periods?property_id=${property_id}&lease_id=${BASE_LEASE_ID}`);
    promise.then( r => {
      store.dispatch({
        type: 'SET_LEASE_PACKAGES',
        packages: r.data
      })
    })
    return promise;
  },
  setDefaultLeaseCharges(default_lease_charges){
    store.dispatch({
      type: 'SET_DEFAULT_LEASE_CHARGES',
      default_lease_charges: default_lease_charges
    })
  },
  setRent(rent){
    store.dispatch({
      type: 'SET_RENT',
      rent: rent
    })
  },
  setPackage(pack){
    store.dispatch({
      type: 'SET_PACKAGE',
      pack: pack
    })
  },
  // fetchPeriods(property_id) {
  //   const promise = axios.get(`/api/lease_periods?property_id=${property_id}&lease_id=${BASE_LEASE_ID}`)
  //   // .then(r => {
  //   //   setLoading(false);
  //   //   store.dispatch({
  //   //     type: 'SET_BATCH_PERIODS',
  //   //     periods: r.data
  //   //   });
  //   //   actions.fetchReport(property);
  //   // }).catch(() => {
  //   //   setLoading(false)
  //   // });
  //   return promise
  // },
  refreshLeaseParams(leaseParams) {
    setLoading(true);
    const {start_date, end_date, unit} = leaseParams;
    const unit_id = store.getState().availableUnits.find(u => u.number === unit).id;
    const params = {
      start_date: start_date.format ? start_date.format('YYYY-MM-DD') : start_date,
      end_date: end_date.format ? end_date.format('YYYY-MM-DD') : end_date,
      unit_id
    };
    const promise = axios.get(`/api/leases/${BASE_LEASE_ID}`, {params});
    promise.then(() => {
      setLoading(false);
    });
    return promise;
  },
  submitForSignature(leaseParams) {
    leaseParams["default_lease_charges"] = store.getState().defaultLeaseCharges.reduce((acc, dlc) => {
      if(dlc.addCharge) acc.push(dlc);
      if(!dlc.unchecked && !dlc.addCharge) acc.push(dlc.id);
      return acc;
    }, []);
    setLoading(true);
    axios.post(`/api/leases`, {bluemoon_params: {...leaseParams, ref: `${BASE_LEASE_ID}`}}).then(() => {
      setLoading(false);
      snackbar({message: "Lease Submitted for signature", args: {type: 'success'}});
    }).catch(r => {
      setLoading(false);
      snackbar({message: r.response.data.error, args: {type: 'error'}});
    });
  },
  fetchAvailableUnits(property_id, startDate) {
    setLoading(true);
    const promise = axios.get(`/api/units/?property_id=${property_id}&start=${startDate}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_AVAILABLE_UNITS',
        availableUnits: [{number: store.getState().lease.unit}].concat(r.data)
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
  }
};

export default actions;
