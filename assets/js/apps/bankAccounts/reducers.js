import {combineReducers} from 'redux';

export default combineReducers({
  bankAccounts(state = [], {type, bankAccounts}){
    if (type === 'SET_BANK_ACCOUNTS') return bankAccounts;
    return state;
  },
  properties(state = [], {type, properties}){
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  },
  accounts(state = [], {type, accounts}){
    if (type === 'SET_ACCOUNTS') return accounts;
    return state;
  }
});