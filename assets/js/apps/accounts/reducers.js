import {combineReducers} from 'redux';

export default combineReducers({
  accounts(state = [], {type, accounts}){
    if (type === 'SET_ACCOUNTS') return accounts;
    return state;
  },
  properties(state = [], {type, properties}){
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  },
  categories(state = [], {type, categories}) {
    if (type === 'SET_CATEGORIES') return categories;
    return state;
  }
});