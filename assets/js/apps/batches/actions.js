import axios from 'axios';
import store from './store';
import setLoading from '../../components/loading';
import snackbar from '../../components/snackbar';

const actions = {
  fetchProperties() {
    setLoading(true);
    axios.get('/api/property_meta').then(r => {
      store.dispatch({
        type: 'SET_PROPERTIES',
        properties: r.data
      });
    });
  },
  fetchAccounts() {
    axios.get('/api/accounts').then(r => {
      setLoading(false);
      store.dispatch({
        type: 'SET_ACCOUNTS',
        accounts: r.data
      });
    });
  },
  fetchResidents(property_id, type) {
    setLoading(true);
    const promise = axios.get(`/api/tenants?property_id=${property_id}&type=${type}`);
    promise.then(r => {
      actions.setResidents(r.data);
      setLoading(false);
    });
    promise.catch(() => {
      snackbar({
        message: 'Unable to get residents',
        args: {
          type: 'error'
        }
      });
      setLoading(false)
    })
  },
  setResidents(residents) {
    store.dispatch({
      type: 'SET_RESIDENTS',
      residents: residents
    });
  },
  saveCharges(batch) {
    setLoading(true);
    const promise = axios.post('/api/accounting_charges', {batch});
    promise.then(() => {
      setLoading(false);
      snackbar({
        message: 'Charges saved',
        args: {
          type: 'success'
        }
      })
    });
    promise.catch(() => {
      setLoading(false);
      snackbar({
        message: 'Unable to save all charges',
        args: {
          type: 'error'
        }
      })
    })
  }
};

export default actions;