import axios from 'axios';
import snackbar from "../../components/snackbar";
import setLoading from '../../components/loading'
import store from './store'
import ajaxDownload from "../../utils/ajaxDownload";

const actions = {
  fetchUnreconciledTransactions(posting_id, params) {
    setLoading(true);
    const promise = axios.get(`/api/reconciliation_postings/${posting_id}`, {params})
    .finally(() => setLoading(false))
    return promise;
  },
  postingPDF(posting){
    const url = `/api/reconciliation_postings/${posting.id}/?pdf_report`
    ajaxDownload(url, `${posting.bank_name}.pdf`)
  },
  createPosting(params) {
    setLoading(true)
    const promise = axios.post('/api/reconciliation_postings', {params})
        .then((r) => snackbar({message: 'Success', args: {type: 'success'}}))
        .catch(() => snackbar({message: 'Error', args: {type: 'error'}}))
        .finally(() => setLoading(false))
    return promise;
  },
  updatePosting(id, params) {
    setLoading(true)
    const promise = axios.patch('/api/reconciliation_postings/' + id, {params})
        .finally(() => setLoading(false))
    return promise;
  },
  fetchPostings(bank_id) {
    const promise = axios.get(`/api/reconciliation_postings/?bank_id=${bank_id}`)
    .then(({data}) => {
      store.dispatch({
        type: 'SET_POSTINGS',
        postings: data
      });
    })
    return promise;
  },
  postReconciliation(posting_id) {
    const promise = axios.patch(`/api/reconciliation_postings/${posting_id}`, {params: {is_posted: true}, post_reconciliation: true})
    .then(() => actions.fetchPostings(store.getState().bankId))
    .then(() => snackbar({message: 'reconciliation posted succesfuly', args: {type: 'success'}}))
    .catch(() => snackbar({message: 'an error occured', args: {type: 'error'}}))
    return promise;
  },
  save(params) {
    const promise = axios.post('/api/reconcile', {params})
    promise.then(() => {
      snackbar({message: "Reconciliation Saved Successfully.", args: {type: 'success'}});
    })
        .catch(() => {
          snackbar({message: "Error Saving Reconciliation", args: {type: 'error'}})
        })
    return promise;
  },
  fetchBankAccounts() {
    const promise = axios.get('/api/bank_accounts')
    .then(({data}) => {
      store.dispatch({
        type: 'SET_BANK_ACCOUNTS',
        bankAccounts: data
      })
      actions.setBankId(data[0].id)
    });
    return promise;
  },
  deletePosting(id){
    setLoading(true);
    const promise = axios.delete('/api/reconciliation_postings/' + id)
    .then(() => actions.fetchPostings(store.getState().bankId))
    .finally(() => setLoading(false))
  },
  undoPosting(id){
    const promise = axios.patch('/api/reconciliation_postings/' + id, {params: {is_posted: false}, undo_posting: true})
    .then(() => actions.fetchPostings(store.getState().bankId))
  },
  setBankId(id) {
    store.dispatch({
      type: 'SET_BANK_ID',
      bankId: id
    })
  }
};

export default actions;
