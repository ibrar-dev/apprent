import {combineReducers} from "redux"

const reducers = {
  invoices(state = [], {type, invoices}) {
    if (type === 'SET_INVOICES') return invoices;
    return state;
  },
  properties(state = [], {type, properties}) {
    if (type === 'SET_PROPERTIES') return properties;
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
  payees(state = [], {type, payees}) {
    if (type === 'SET_PAYEES') return payees;
    return state;
  },
  invoice(state = null, {type, invoice}) {
    if (type === 'SET_INVOICE') return invoice;
    return state;
  },
  filters(state = {}, {type, filters}) {
    if (type === 'SET_FILTERS') return filters;
    return state;
  }
};
export default combineReducers(reducers);
