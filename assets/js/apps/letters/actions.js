import axios from 'axios';
import store from './store';
import setLoading from '../../components/loading';
import snackbar from '../../components/snackbar';

const actions = {
  fetchProperties() {
    axios.get('/api/property_meta').then(r => {
      store.dispatch({
        type: 'SET_PROPERTIES',
        properties: r.data
      });
      const {property} = store.getState();
      if (!property.id) return actions.viewProperty(r.data[0]);
      r.data.some(p => {
        if (p.id === property.id) {
          actions.viewProperty(p);
          return true;
        }
      });
    })
  },
  viewProperty(property) {
    actions.fetchTenants(property);
    actions.fetchLetterTemplates(property);
    store.dispatch({
      type: 'SET_PROPERTY',
      property
    });
  },
  fetchLetterTemplates(property) {
    setLoading(true);
    const promise = axios.get(`/api/letter_templates?property_id=${property.id}`);
    promise.then(r => {
      setLoading(false);
      store.dispatch({
        type: 'SET_LETTERS',
        letters: r.data
      })
    });
    promise.catch(() => {
      setLoading(false);
      snackbar({
        message: 'Unable to get letters',
        args: {type: 'danger'}
      })
    })
  },
  fetchTenants(property) {
    setLoading(true);
    const promise = axios.get(`/api/tenants?property_id=${property.id}&with_bal`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_RESIDENTS',
        residents: r.data
      });
      setLoading(false);
    });
    promise.catch(() => {
      setLoading(false);
      snackbar({
        message: 'Unable to fetch residents',
        args: {type: 'error'}
      })
    })
  },
  selectResident(id) {
    const selected = [...store.getState().selectedResidents];
    if (selected.indexOf(id) === -1) {
      selected.push(id);
    } else {
      selected.splice(selected.indexOf(id), 1)
    }
    store.dispatch({
      type: 'SET_SELECTED',
      selected
    })
  },
  selectAll(residents, select) {
    store.dispatch({
      type: 'SET_SELECTED',
      selected: select ? residents.map(r => r.id) : []
    });
  },
  generateLetters(generate) {
    setLoading(true);
    const promise = axios.post('/api/letter_templates', {generate});
    promise.then(() => {
      setLoading(false);
    }).catch(() => {
      setLoading(false);
      snackbar({
        message: 'Error generating letters',
        args: {type: 'danger'}
      })
    });
    return promise;
  },

  createTemplate(template) {
    setLoading(true);
    const {property} = store.getState();
    const params = {property_id: property.id, ...template};
    const promise = axios.post('/api/letter_templates', {letter_template: params});
    promise.then(() => {
      snackbar({
        message: 'New Template Created Successfully',
        args: {type: 'success'}
      });
      actions.fetchLetterTemplates(property);
    }).catch(() => {
      snackbar({
        message: 'An Error Occurred',
        args: {type: 'danger'}
      })
    }).finally(() => {
      setLoading(false);
    });
    return promise;
  },
  updateTemplate(template) {
    setLoading(true);
    const promise = axios.patch('/api/letter_templates/' + template.id, {letter_template: template});
    promise.then(() => {
      snackbar({
        message: 'Template Updated Successfully',
        args: {type: 'success'}
      });
      actions.fetchLetterTemplates(store.getState().property);
    }).catch(() => {
      snackbar({
        message: 'An Error Occurred',
        args: {type: 'danger'}
      })
    }).finally(() => {
      setLoading(false);
    });
    return promise;
  },
  getHtmlTemplatePreview(html) {
    setLoading(true);
    const promise = axios.post(`/api/letter_templates/`, {html, property_id: store.getState().property.id});
    promise.finally(() => {
      setLoading(false);
    });
    return promise;
  },
  getTemplatePreview(id) {
    setLoading(true);
    const promise = axios.get(`/api/letter_templates/` + id);
    promise.finally(() => {
      setLoading(false);
    });
    return promise;
  },
  deleteTemplate(id) {
    setLoading(true);
    const promise = axios.delete(`/api/letter_templates/` + id);
    promise.then(() => {
      actions.fetchLetterTemplates(store.getState().property);
    }).finally(() => {
      setLoading(false);
    });
    return promise;
  },
  fetchRecurringLetters(property_id) {
    setLoading(true);
    const promise = axios.get(`/api/recurring_letters?property_id=${property_id}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_RECURRING_LETTERS',
        letters: r.data
      });
      setLoading(false)
    });
    promise.catch(() => {
      snackbar({
        message: 'Unable to get scheduled letters',
        args: {type: 'danger'}
      });
      setLoading(false)
    })
  },
  fetchAdmins() {
    const promise = axios.get('/api/admins?fetchEmployees');
    promise.then(r => {
      store.dispatch({
        type: 'SET_ADMINS',
        admins: r.data
      })
    })
  },
  previewTenantsList(listId) {
    const promise = axios.get(`/api/recurring_letters/${listId}?preview`);
    promise.then(r => {
      store.dispatch({
        type: 'PREVIEW_TENANTS',
        previewTenants: r.data
      });
    })
    .catch( () => snackbar({
      message: 'Error fetching tenants',
      arg: {type: 'danger'}
    }));
    return promise;
  },
  generateLettersEarly(id) {
    const promise = axios.get(`/api/recurring_letters/${id}`);
    promise.then(() => {
        snackbar({
          message: 'Letters currently generating, please wait a few moments for them to appear in tenant accounts',
          args: {type: 'success'}
        }) 
    })
    .catch(() => {
      snackbar({
        message: 'Error generating letters',
        args: {type: 'danger'}
      })
    });
    return promise;
  },
  saveRecurringLetter(recurring_letter) {
    const promise = axios.post('/api/recurring_letters', {recurring_letter});
    promise.then(r => {
      actions.fetchRecurringLetters(recurring_letter.property_id);
      snackbar({
        message: 'Recurring Letter Saved',
        args: {type: 'success'}
      });
    });
    promise.catch(e => {
      snackbar({
        message: e.response.data,
        args: {type: 'error'}
      });
    })
  },
  updateRecurringLetter(id, recurring_letter) {
    const promise = axios.patch(`/api/recurring_letters/${id}`, {recurring_letter});
    promise.then(() => {
      actions.fetchRecurringLetters(recurring_letter.property_id);
      snackbar({
        message: 'Recurring Letter Updated',
        args: {type: 'success'}
      });
    });
    promise.catch(e => {
      snackbar({
        message: e.response.data,
        args: {type: 'error'}
      });
    })
  }
};

export default actions;
