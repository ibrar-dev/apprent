import axios from 'axios';
import store from './store';
import moment from 'moment'

const actions = {
  fetchChecks() {
    axios.get('/api/checks').then(r => {
      store.dispatch({
        type: 'SET_CHECKS',
        checks: r.data
      });
    });
  },
  fetchInvoicings() {
    const {filters} = store.getState();
    axios.get('/api/invoicings', {params: filters}).then(r => {
      store.dispatch({
        type: 'SET_INVOICINGS',
        invoicings: r.data
      });
    });
  },
  refresh() {
    actions.fetchChecks();
    actions.fetchInvoicings();
  },
  fetchAccounts() {
    axios.get('/api/accounts?type=cash').then(r => {
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
    axios.get('/api/payees').then(r => {
      store.dispatch({
        type: 'SET_PAYEES',
        payees: r.data
      });
    });
  },
  fetchProperties() {
    const promise = axios.get('/api/properties?min');
    promise.then(r => {
      store.dispatch({
        type: 'SET_PROPERTIES',
        properties: r.data
      });
    })
  },
  printChecks(pdf_ids){
    return axios.get(`/api/checks?pdf_ids=${pdf_ids}`)
  },
  setMode(mode) {
    store.dispatch({
      type: 'SET_MODE',
      mode
    });
  },
  select(invoicing) {
    const {selected} = store.getState();
    const checksAmount = invoicing.checks.reduce((sum, c) => sum + parseFloat(c.amount), 0);
    invoicing.to_pay = parseFloat(invoicing.amount) - checksAmount;
    selected.push(invoicing);
    store.dispatch({
      type: 'SET_SELECTED',
      selected: [...selected]
    })
  },
  unselect(invoicing) {
    // debugger
    const {selected: s} = store.getState();
    const selected = s.filter(i => i.id !== invoicing.id);
    // debugger
    store.dispatch({
      type: 'SET_SELECTED',
      selected
    })
  },
  selectCheck(check) {
    const {selectedChecks} = store.getState();
    selectedChecks.push(check);
    store.dispatch({
      type: 'SET_SELECTED_CHECKS',
      selected: [...selectedChecks]
    })
  },
  unselectCheck(check) {
    const {selectedChecks: s} = store.getState();
    const selectedChecks = s.filter(i => i.id !== check.id);
    store.dispatch({
      type: 'SET_SELECTED_CHECKS',
      selected: selectedChecks
    })
  },
  setAmount(invoicingId, {target: {value}}) {
    const {selected: s} = store.getState();
    const selected = s.map(i => i.id === invoicingId ? {...i, to_pay: value} : i);
    store.dispatch({
      type: 'SET_SELECTED',
      selected
    })
  },
  setFilter(field, {target: {value}}) {
    const {filters} = store.getState();
    store.dispatch({
      type: 'SET_FILTERS',
      filters: {...filters, [field]: value}
    });
    actions.fetchInvoicings()
  },
  deleteCheck(params) {
    const promise = axios.delete(`/api/checks/${params.id}?cascade=${params.cascade}`);
    promise.then(actions.refresh);
    return promise;
  },
  saveCheck(params) {
    return params.id ? actions.updateCheck(params) : actions.createCheck(params);
  },
  getShowCheckById(id){
    const promise = axios.get(`/api/checks/${id}`);
    promise.then(actions.refresh);
    return promise;
  },
  createCheck(params) {
    const promise = axios.post('/api/checks', {check: params});
    promise.then(actions.refresh);
    return promise;
  },
  updateCheck(params) {
    const promise = axios.patch('/api/checks/' + params.id, {check: params});
    promise.then(actions.refresh);
    return promise;
  }
};

export default actions;