import {combineReducers} from 'redux';

export default combineReducers({
  templates(state = [], {type, templates}){
    if (type === 'SET_TEMPLATES') return templates;
    return state;
  },
  accounts(state = [], {type, accounts}){
    if (type === 'SET_ACCOUNTS') return accounts;
    return state;
  },
  template(state = null, {type, template}){
    if (type === 'SET_TEMPLATE') return template;
    return state;
  }
});