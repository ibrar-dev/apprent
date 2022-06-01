import {combineReducers} from 'redux';

const reducers = {
  transactions(state = [], {type, transactions}) {
    if (type === 'SET_TRANSACTIONS') return transactions;
    return state;
  },
  applicants(state = [], {type, applicants}) {
    if (type === 'SET_APPLICANTS') return applicants;
    return state;
  },
  bankAccounts(state = [], {type, bankAccounts}) {
    if (type === 'SET_BANK_ACCOUNTS') return bankAccounts;
    return state;
  }
};

export default combineReducers(reducers)
