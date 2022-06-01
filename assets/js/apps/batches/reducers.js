import {combineReducers} from 'redux';

export default combineReducers({
  properties(state = [], {type, properties}){
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  },
  accounts(state = [], {type, accounts}){
    if (type === 'SET_ACCOUNTS') return accounts;
    return state;
  },
  residents(state = [], {type, residents}) {
    if (type === 'SET_RESIDENTS') return residents;
    return state;
  }
});