import axios from 'axios';
import store from "./store"
import setLoading from '../../components/loading';

let actions = {
  fetchApplicant(id) {
    actions.applicationId = id;
    setLoading(true);
    axios.get(`/api/applicants/${id}`).then(r => {
      store.dispatch({
        type: 'SET_TRANSACTIONS',
        transactions: r.data.transactions
      });
      store.dispatch({
        type: 'SET_APPLICANTS',
        applicants: r.data.applicants
      });
      setLoading(false);
    })
  },
  fetchBankAccounts(propertyId) {
    axios.get('/api/bank_accounts?property_id=' + propertyId).then(r => {
      store.dispatch({
        type: 'SET_BANK_ACCOUNTS',
        bankAccounts: r.data
      });
    });
  },
  updatePayment(params) {
    setLoading(true);
    const promise = axios.patch(`/api/payments/${params.id}`, {payment: params});
    promise.then(() => {
      actions.fetchApplicant(actions.applicationId)
    });
    return promise;
  },
  createCheck(params) {
    const promise = axios.post('/api/checks', {check: params});
    promise.then(() => {
      actions.fetchApplicant(actions.applicationId)
    });
    return promise;
  },
};


export default actions
