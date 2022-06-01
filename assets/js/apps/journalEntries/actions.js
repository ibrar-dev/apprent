import axios from 'axios';
import store from "./store"
import snackbar from '../../components/snackbar';

let actions = {
  fetchJournalEntries() {
    axios.get('/api/journal_pages').then(r => {
      store.dispatch({
        type: 'SET_JOURNAL_PAGES',
        journalPages: r.data,
      });
    });
  },
  fetchAccounts() {
    axios.get('/api/accounts').then(r => {
      store.dispatch({
        type: 'SET_ACCOUNTS',
        accounts: r.data,
      });
    });
  },
  fetchProperties() {
    axios.get('/api/property_meta').then(r => {
      store.dispatch({
        type: 'SET_PROPERTIES',
        properties: r.data,
      });
    });
  },
  updatePage(params) {
    const promise = axios.patch(`/api/journal_pages/${params.id}`, {journal_page: params});
    promise.then(() => {
      snackbar({
        message: "Journal page updated",
        args: {type: 'success'}
      });
      actions.fetchJournalEntries();
    });
    return promise;
  },
  createPage(params) {
    const promise = axios.post('/api/journal_pages', {journal_page: params});
    promise.then(() => {
      snackbar({
        message: "Journal page created",
        args: {type: 'success'}
      });
      actions.fetchJournalEntries();
    });
    return promise;
  },
  deletePage(params) {
    const promise = axios.delete('/api/journal_pages/' + params.id);
    promise.then(() => {
      snackbar({
        message: "Journal page deleted",
        args: {type: 'success'}
      });
      actions.fetchJournalEntries();
    });
    return promise;
  },
  editPage(entry) {
    store.dispatch({type: 'SET_EDIT_ENTRY', entry});
  }
};

export default actions;
