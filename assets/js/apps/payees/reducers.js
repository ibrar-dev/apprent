import {combineReducers} from 'redux';

export default combineReducers({
  payees(state = [], {type, payees}){
    if (type === 'SET_PAYEES') return payees;
    return state;
  },
  payee(state = null, {type, payee}){
    if (type === 'SET_PAYEE') return payee;
    return state;
  }
});