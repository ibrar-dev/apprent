import {combineReducers} from 'redux';

export default combineReducers({
  postings(state = [], {type, postings}){
    if (type === 'SET_POSTINGS') return postings;
    return state;
  },
  bankAccounts(state = [], {type, bankAccounts}){
    if (type === 'SET_BANK_ACCOUNTS') return bankAccounts;
    return state;
  },
  bankId(state = null, {type, bankId}){
    if (type === 'SET_BANK_ID') return bankId;
    return state;
  }
});
