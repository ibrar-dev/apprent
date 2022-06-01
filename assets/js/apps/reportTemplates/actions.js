import axios from 'axios';
import store from './store';
import snackbar from '../../components/snackbar';

const actions = {
  fetchTemplates() {
    axios.get('/api/report_templates').then(r => {
      store.dispatch({
        type: 'SET_TEMPLATES',
        templates: r.data
      });
    });
  },
  fetchAccounts() {
    const promise = axios.get('/api/accounts');
    promise.then(r => {
      store.dispatch({
        type: 'SET_ACCOUNTS',
        accounts: r.data
      });
    });
    return promise;
  },
  deleteTemplate(params) {
    const promise = axios.delete('/api/report_templates/' + params.id);
    promise.then(actions.fetchTemplates);
    return promise;
  },
  createTemplate(params) {
    const promise = axios.post('/api/report_templates', {report_template: params});
    promise.then(actions.fetchTemplates);
    return promise;
  },
  duplicateTemplate(template) {
    const params = {...template, name: `${template.name} Copy`};
    delete params.id;
    return actions.createTemplate(params);
  },
  updateTemplate(params) {
    const promise = axios.patch('/api/report_templates/' + params.id, {report_template: params});
    promise.then(actions.fetchTemplates);
    return promise;
  },
  saveTemplate(params) {
    const func = params.id ? 'updateTemplate' : 'createTemplate';
    return actions[func](params);
  },
  setTemplate(template) {
    store.dispatch({
      type: 'SET_TEMPLATE',
      template
    });
  },
  createAccount(params) {
    return axios.post('/api/accounts', {account: params});
  },
  updateAccount(account) {
    const promise = axios.patch(`/api/accounts/${account.id}`, {account});
    promise.then(r => {
      snackbar({
        message: 'Account Updated',
        args: {type: 'success'}
      });
    })
    promise.catch(() => {
      snackbar({
        message: 'Account Not Updated!\nPlease update account from the chart of accounts',
        args: {type: 'danger'}
      });
    });
    return promise;
  }
};

export default actions;