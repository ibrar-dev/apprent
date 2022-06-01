import {combineReducers} from 'redux';

export default combineReducers({
  checks(state = [], {type, checks}) {
    if (type === 'SET_CHECKS') return checks;
    return state;
  },
  invoicings(state = [], {type, invoicings}) {
    if (type === 'SET_INVOICINGS') return invoicings;
    return state;
  },
  payees(state = [], {type, payees}) {
    if (type === 'SET_PAYEES') return payees;
    return state;
  },
  selected(state = [], {type, selected}) {
    if (type === 'SET_SELECTED') return selected;
    return state;
  },
  selectedChecks(state = [], {type, selected}) {
    if (type === 'SET_SELECTED_CHECKS') return selected;
    return state;
  },
  accounts(state = [], {type, accounts}) {
    if (type === 'SET_ACCOUNTS') return accounts;
    return state;
  },
  bankAccounts(state = [], {type, bankAccounts}) {
    if (type === 'SET_BANK_ACCOUNTS') return bankAccounts;
    return state;
  },
  properties(state = [], {type, properties}) {
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  },
  filters(state = {}, {type, filters}) {
    if (type === 'SET_FILTERS') return filters;
    return state;
  },
  mode(state = 'checks', {type, mode}) {
    if (type === 'SET_MODE') return mode;
    return state;
  }
});