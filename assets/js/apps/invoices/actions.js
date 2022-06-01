import axios from 'axios';
import store from "./store";
import snackbar from '../../components/snackbar';
import moment from "moment";

const actions = {
  fetchInvoices() {
    const {filters} = store.getState();
    const promise = axios.get('/api/invoices', {params: filters});
    promise.then(r => {
      store.dispatch({
        type: 'SET_INVOICES',
        invoices: r.data
      });
      const {invoice} = store.getState();
      if (invoice) {
        actions.setInvoice(r.data.filter(i => i.id === invoice.id)[0]);
      }
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
  fetchBankAccounts() {
    axios.get('/api/bank_accounts').then(r => {
      store.dispatch({
        type: 'SET_BANK_ACCOUNTS',
        bankAccounts: r.data
      });
    });
  },
  fetchPayees() {
    axios.get('/api/payees?meta').then(r => {
      store.dispatch({
        type: 'SET_PAYEES',
        payees: r.data
      });
    });
  },
  fetchProperties() {
    axios.get('/api/property_meta').then(r => {
      store.dispatch({
        type: 'SET_PROPERTIES',
        properties: r.data
      });
    });
  },
  createInvoice(params) {
    const promise = axios.post('/api/invoices', {invoice: params});
    promise.then(() => {
      actions.fetchInvoices();
      snackbar({message: "Invoice successfully saved.", args: {type: 'success'}});
    });
    promise.catch(e => {
      snackbar({
        message: e.response.data,
        args: {type: 'error'}
      });
    })
    return promise;
  },
  createPayee(params) {
    const promise = axios.post('/api/payees', {payee: params});
    promise.then(actions.fetchPayees);
    return promise;
  },
  updateInvoice(params) {
    const promise = axios.patch('/api/invoices/' + params.id, {invoice: params});
    promise.then(() => {
      actions.fetchInvoices().then(() => {
        snackbar({message: 'Invoice Updated', args: {type: 'success'}});
      })
    });
    return promise;
  },
  deleteInvoice(params) {
    const promise = axios.delete('/api/invoices/' + params.id);
    promise.then(actions.fetchInvoices);
    return promise;
  },
  setInvoice(invoice) {
    store.dispatch({
      type: 'SET_INVOICE',
      invoice
    })
  },
  createPayment(payment) {
    const promise = axios.post('/api/invoice_payments/', {payment});
    promise.then(actions.fetchInvoices);
    return promise;
  },
  createPayments(payments) {
    const promise = axios.post('/api/invoice_payments/', {payments});
    promise.then(actions.fetchInvoices);
    return promise;
  },
  createBatchPayments(batch_payments) {
    const promise = axios.post('/api/invoice_payments/', {batch_payments});
    promise.then(actions.fetchInvoices);
    promise.then(() => {
      snackbar({message: 'Invoices Paid', args: {type: 'success'}});
      actions.fetchInvoices();
      actions.fetchBankAccounts()
    }).catch(r => {
      snackbar({message: r.response.data.error, args: {type: 'danger'}});
    });
    return promise;
  },
  deletePayment(payment) {
    const promise = axios.delete('/api/invoice_payments/' + payment.id);
    promise.then(actions.fetchInvoices);
    return promise;
  },
  createAccount(account) {
    const promise = axios.post('/api/accounts/', {account});
    promise.then(actions.fetchAccounts);
    return promise;
  },
  setFilter(field, {target: {value}}) {
    const newVal = (moment.isMoment(value)) ? moment(value).format() : value;
    let {filters} = store.getState();
    if (value){
      filters = {...filters, [field]: newVal}
    }
    else {
      delete filters[field]
    }
    store.dispatch({
      type: 'SET_FILTERS',
      filters
    });
    actions.fetchInvoices()
  },
  printChecks(pdf_ids){
    return axios.get(`/api/checks?pdf_ids=${pdf_ids}`)
  }
};

export default actions;
