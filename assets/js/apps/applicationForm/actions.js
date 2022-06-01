import axios from 'axios';
import JSEncrypt from 'jsencrypt';
import sha256 from 'crypto-js/sha256';
import store from "./store"

const actions = {
  initializeApplication(property) {
    store.dispatch({type: 'INITIALIZE_APPLICATION', property});
    if (window.APPLICATION_JSON) {
      const {application} = store.getState();
      actions._processLoadedForm(APPLICATION_JSON, application);
      store.dispatch({
        type: 'SET_PROPERTY',
        property: window.PROPERTY_DATA
      });
    }
  },

  fetchProperty() {
    if (window.PROPERTY_DATA) return;
    const params = window.location.search;
    const propertyCode = location.href.split('/').reverse()[0].replace(params, "");
    const promise = axios.get('/api/properties?code=' + propertyCode);
    promise.then(r => {
      store.dispatch({
        type: 'SET_PROPERTY',
        property: r.data
      });
      actions.initializeApplication(r.data)
    });
    return promise;
  },

  setProperty(property) {
    store.dispatch({type: 'SET_PROPERTY', property});
  },

  setStage(stage) {
    store.dispatch({type: 'SET_STAGE', stage})
  },

  nextStage(increment) {
    const {application, stage} = store.getState();
    const stages = Object.keys(application);
    const currentStage = stages.indexOf(stage);
    let newStage = stages[currentStage + increment];
    if (newStage === 'income') {
      newStage = stages[currentStage + increment + increment];
    }
    store.dispatch({type: 'SET_STAGE', stage: newStage});
  },

  setApplicationField(section, field, value) {
    store.dispatch({type: 'EDIT_APPLICATION_FIELD', section, field, value});
  },

  addToCollection(section, value) {
    store.dispatch({type: 'ADD_TO_COLLECTION', section, value});
  },

  editCollection(section, index, field, value) {
    store.dispatch({type: 'EDIT_COLLECTION', section, index, field, value});
  },

  formatCollection(section, index, field, value) {
    store.dispatch({type: 'FORMAT_COLLECTION', section, index, field, value});
  },

  deleteCollection(section, id) {
    store.dispatch({type: 'DELETE_COLLECTION', section, id});
  },

  resetCollection(section, models) {
    store.dispatch({type: 'RESET_COLLECTION', section, models});
  },

  validateApplication() {
    const {application, property} = store.getState();
    const applicationFields = Object.keys(application);
    return applicationFields.every(field => !application[field].hasErrors());
  },

  applicationJson() {
    const json = {};
    const {application, language, startTime, savedFormId} = store.getState();
    const referral = new URLSearchParams(window.location.search).get('referral')

    const applicantionFields = Object.keys(application);
    applicantionFields.pop(); // drop the review field
    applicantionFields.forEach(k => json[k] = application[k].data());

    json["lang"] = language.language;
    json["start_time"] = startTime;
    json["saved_form_id"] = savedFormId;

    if (!json.income.present) delete json.income;
    if (referral) json.referral = referral;
    if (window.deviceId) {
      const sign = new JSEncrypt();
      sign.setPrivateKey(window.privateCert);
      const message = Math.random().toString(36).substring(2);
      const signed = sign.sign(message, sha256, 'sha256');
      json.message = message;
      json.device_id = window.deviceId;
      json.signed = signed;
    }
    // Stick the property's rental application terms and conditions in there too
    json.terms_and_conditions = window.PROPERTY_TERMS || "",
    json.prospect_id = PROSPECT_PARAMS.id;

    return json;
  },

  saveForm() {
    const {property, application: storeApp, startTime, language} = store.getState();
    const applicationFieldKeys = Object.keys(storeApp);
    const formSummary = {};
    applicationFieldKeys.forEach(sect => {
      if (storeApp[sect].done) {
        formSummary[sect] = {done: true}
      } else if (storeApp[sect].models) {
        formSummary[sect] = {collectionErrors: storeApp[sect].models.map(m => m.errors)}
      } else {
        formSummary[sect] = {errors: storeApp[sect].errors}
      }
    })
    const application = actions.applicationJson();
    delete application.documents;
    return axios.post(
      '/api/forms',
      {
        saved_form: application,
        property_id: property.id,
        form_data: {
          form_summary: formSummary,
          start_time: startTime,
          language: language.language,
        }
      }
    );
  },

  setForm({data}) {
    const {form, id} = data;
    const {application, property} = store.getState();
    actions.initializeApplication(property);
    actions.setStartTime(form.start_time);
    actions.setSavedFormId(id);
    actions._processLoadedForm(form, application);
  },

  setStartTime(time) {
    store.dispatch({type: 'SET_START_TIME', time});
  },

  setSavedFormId(id) {
    store.dispatch({type: 'SET_SAVED_FORM_ID', id});
  },

  _processLoadedForm(form, application) {
    for (const section in form) {
      if (form.hasOwnProperty(section)) {
        const value = form[section];
        if (value instanceof Array) {
          actions._processCollection(section, value, application);
        } else {
          actions._processField(section, value);
        }
      }
    }
  },

  _processField(section, obj) {
    for (const field in obj) {
      if (obj.hasOwnProperty(field)) {
        actions.setApplicationField(section, field, obj[field]);
      }
    }
  },

  _processCollection(section, collection, application) {
    if (!application.hasOwnProperty(section)) return;
    const constructor = application[section].type;
    const newModels = collection.map(v => {
      const model = new constructor();
      model.importObj(v);
      return model
    });
    actions.resetCollection(section, newModels);
  },

  loadForm(params) {
    const promise = axios.post('/api/forms/get', params);
    promise.then(actions.setForm).catch(e => e);
    return promise;
  },

  submissionData(paymentData) {
    actions.paid = paymentData.amount;
    const {property} = store.getState();
    const data = {
      payment: paymentData,
      property_id: property.id,
      application_form: actions.applicationJson(),
    };
    data.application_form.documents = [];
    const documents = store.getState().application.documents.models;
    const promises = documents.map(d => d.fileData().upload());
    return new Promise(function (resolve) {
      Promise.all(promises).then(() => {
        documents.forEach(doc => {
          const uuid = doc.fileData().uuid;
          if (uuid) data.application_form.documents.push({type: doc.data(), url: {uuid}});
        });
        resolve(data);
      });
    });
  },

  submitPayment(paymentObj) {
    const payment = {
      token_description: paymentObj.token_description,
      token_value: paymentObj.token_value,
      payer_name: paymentObj.name,
      last_4: paymentObj.number.slice(-4),
      payment_type: "cc",
      source: "customer-app-payment-form",
      amount: paymentObj.fees.reduce((a, b) => (a.amount + b.amount)),
      fees: paymentObj.fees,
      agreement_accepted_at: paymentObj.agreement_accepted_at,
      agreement_text: paymentObj.agreement_text
    };

    return new Promise((resolve, reject) => {
      actions.submissionData(payment).then(data => {
        axios.post('/api/rent_applications', {...data, client: window.CLIENT_SCHEMA}).then(resolve).catch(reject);
      });
    });
  },

  setLanguage(lang) {
    store.dispatch({
      type: 'SET_LANGUAGE',
      language: lang
    })
  },

  updateApplication() {
    const json = {};
    const {application} = store.getState();
    const applicationFields = Object.keys(application);
    applicationFields.pop(); // drop the review field
    applicationFields.forEach(k => json[k] = application[k].data());
    return axios.patch(`/api/applications/${window.APPLICATION_JSON.id}`, {application: json, full: true});
  }
};

export default actions;
