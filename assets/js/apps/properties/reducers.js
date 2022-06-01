import {combineReducers} from "redux"

const reducers = {
  properties: (state = [], action) => {
    if (action.type === 'SET_PROPERTIES') return action.properties;
    return state;
  },
  documents(state = [], {type, adminDocuments}) {
    if (type === 'SET_ADMIN_DOCUMENTS') return adminDocuments;
    return state;
  },
  property(state = {}, {type, property}) {
    if (type === 'SET_PROPERTY') return property;
    return state;
  },
  accounts(state = {}, {type, accounts}) {
    if (type === 'SET_ACCOUNTS') return accounts;
    return state;
  },
  bankAccounts(state = [], {type, bankAccounts}) {
    if (type === 'SET_BANK_ACCOUNTS') return bankAccounts;
    return state;
  },
  filters: (state = {}, action) => {
    switch (action.type) {
      case 'ADD_FILTER':
        state[action.filter] = {value: action.value, predicate: action.predicate};
        return state;
      case 'REMOVE_FILTER':
        delete state[action.filter];
        return state;
      default:
        return state
    }
  },
  specs: (state = [], action) => {
    switch (action.type) {
      case 'SET_SPECS':
        return action.specs;
      default:
        return state
    }
  },
  phoneLines(state = [], {type, phoneLines}) {
    if (type === 'SET_PHONE_LINES') return phoneLines;
    return state;
  },
  openings(state = [], {type, openings}) {
    if (type === 'SET_OPENINGS') return openings;
    return state;
  },
  closures(state = [], {type, closures}) {
    if (type === 'SET_CLOSURES') return closures;
    return state;
  },
  integrations(state = [], {type, integrations}) {
    if (type === 'SET_INTEGRATIONS') return integrations;
    return state;
  },
  features(state = [], {type, features}) {
    if (type === 'SET_FEATURES') return features;
    return state;
  },
  floorPlans(state = [], {type, floorPlans}) {
    if (type === 'SET_FLOOR_PLANS') return floorPlans;
    return state;
  },
  mode(state = 'floorPlans', {type, mode}) {
    if (type === 'SET_MODE') return mode;
    return state;
  },
  units(state = [], {type, units}) {
    if (type === 'SET_UNITS') return units;
    return state;
  },
  chargeCodes(state = [], {type, chargeCodes}) {
    if (type === 'SET_CHARGE_CODES') return chargeCodes;
    return state;
  }
};

export default combineReducers(reducers);
