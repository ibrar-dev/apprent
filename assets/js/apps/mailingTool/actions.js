import axios from 'axios';
import store from './store';
import setLoading from '../../components/loading';
import snackbar from '../../components/snackbar';

const actions = {
  fetchProperties() {
    setLoading(true);
    const promise = axios.get('/api/properties?min');
    promise.then(r => {
      store.dispatch({
        type: 'SET_PROPERTIES',
        properties: r.data
      });
      setLoading(false)
    });
    promise.catch(() => {
      snackbar({
        message: 'Unable to fetch properties',
        args: {type: 'error'}
      })
    })
  },
  fetchRecipients(type) {
    setLoading(true);
    const promise = axios.get(`/api/mailings?type=${type}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_SELECTED',
        selected: r.data
      })
      setLoading(false);
    });
    promise.catch(() => {
      snackbar({
        message: 'Unable to fetch recipients',
        args: {type: 'error'}
      })
    })
  },
  fetchPropertyRecipients(property_id, type) {
    setLoading(true);
    const promise = axios.get(`/api/mailings?property_id=${property_id}&type=${type}`);
    promise.then(r => {
      const residents = store.getState().selectedRecipients;
      store.dispatch({
        type: 'SET_SELECTED',
        selected: residents.concat(r.data)
      });
      setLoading(false);
    });
    promise.catch(() => {
      setLoading(false);
    })
  },
  setSelectedRecipients(selected) {
    store.dispatch({
      type: 'SET_SELECTED',
      selected
    })
  },
  setPropertyIds(presets){
      store.dispatch({
      type: 'SET_ACTIVE_PRESETS',
        activePresets: presets
    })
  },
  clearSelection() {
    store.dispatch({
      type: 'SET_SELECTED',
      selected: []
    })
  },
  createMailing(recipients, mailing, send_at) {
    setLoading(true);
    const email = new FormData();
    Object.keys(mailing).forEach(key => {
      const value = mailing[key];
      if (Array.isArray(value)) {
        value.forEach(v => email.append(`resident_email[${key}][]`, v));
      } else {
        email.append(`resident_email[${key}]`, mailing[key]);
      }
    });
    email.append(`resident_email[recipients]`, JSON.stringify(recipients));
    email.append(`resident_email[send_at]`, JSON.stringify(send_at));
    const promise = axios.post(`/api/mailings`, email);
    promise.then(() => {
      setLoading(false);
      snackbar({
        message: 'Message Sent',
        args: {type: 'success'}
      })
    });
    promise.catch(() => {
      setLoading(false);
      snackbar({
        message: 'Message Failed To Send',
        args: {type: 'error'}
      })
    });
    return promise;
  },
  createScheduledMailing(recipients, mailing) {
    setLoading(true);
    const email = new FormData();
    Object.keys(mailing).forEach(key => {
      const value = mailing[key];
      if (Array.isArray(value)) {
        value.forEach(v => email.append(`scheduled_email[${key}][]`, v));
      } else {
        email.append(`scheduled_email[${key}]`, mailing[key]);
      }
    });
    email.append(`scheduled_email[recipients]`, JSON.stringify(recipients));
    const promise = axios.post(`/api/mailings`, email);
    promise.then(() => {
      setLoading(false);
      snackbar({
        message: 'Message Scheduled',
        args: {type: 'success'}
      })
    });
    promise.catch(() => {
      setLoading(false);
      snackbar({
        message: 'Message Failed To Save',
        args: {type: 'error'}
      })
    });
    return promise;
  },
  setAllRecipients(value) {
    const recipients = store.getState().selectedRecipients;
    let newList = [];
    recipients.forEach(r => {
      r.checked = value;
      newList.push(r)
    });
    actions.setSelectedRecipients(newList);
  },
  fetchMailTemplates() {
    const promise = axios.get('/api/mail_templates');
    promise.then(r => {
      store.dispatch({
        type: 'SET_TEMPLATES',
        templates: r.data
      })
    })
  },
  fetchTemplateProperties(template_id) {
    const promise = axios.get(`/api/property_templates/${template_id.template_id}`, {template_id});
    promise.then(r => {
      store.dispatch({
        type: 'SET_TEMPLATES_PROPERTIES',
        propertiesTemplate: r.data
      })
    })
  },
  createTemplate(mail_template) {
    const promise = axios.post('/api/mail_templates', {mail_template});
    promise.then(r => {
      snackbar({
        message: 'Template Saved',
        args: {type: 'success'}
      });
      actions.fetchMailTemplates();
    })
  },
editTemplate(mail_template, id) {
  const promise = axios.patch(`/api/mail_templates/${mail_template.id}`, {mail_template});
  promise.then(r => {
    snackbar({
      message: 'Template Saved',
      args: {type: 'success'}
    });
    actions.fetchMailTemplates();
  })
},
  deleteTemplate(id) {
    const promise = axios.delete(`/api/mail_templates/${id}`);
    promise.then(r => {
      snackbar({
        message: 'Template Deleted',
        args: {type: 'success'}
      });
      actions.fetchMailTemplates();
    })
  },
  createPropertyTemplate(property_template) {
    const promise = axios.post('/api/property_templates', {property_template});
    promise.then(r => {
      snackbar({
        message: 'Template Saved',
        args: {type: 'success'}
      });
      actions.fetchMailTemplates();
    })
  },
  deleteAllTemplates(template_id) {
    const promise = axios.delete(`/api/property_templates/${template_id.template_id}` );
    promise.then(r => {
      snackbar({
        message: 'Template Updated',
        args: {type: 'success'}
      })
    })
  },
  propertyTemplateAction(property_template) {
      const promise = axios.post('/api/property_templates', {property_template});
      promise.then(r => {
        snackbar({
          message: 'Template Saved',
          args: {type: 'success'}
        })
        actions.fetchMailTemplates();
      })
    },
  propertyTemplates(property_ids) {
    const promise = axios.get(`/api/property_templates?property_ids=${property_ids.property_ids}`)
    promise.then(r => {
      store.dispatch({
        type: 'SET_TEMPLATES',
        templates: r.data
      })
    })
  },
};

export default actions;