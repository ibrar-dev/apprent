import {combineReducers} from 'redux';

const currentYear = (new Date()).getUTCFullYear();

export default combineReducers({
  properties(state = [], {type, properties}){
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  },
  property(state = {}, {type, property}) {
    if (type === 'SET_PROPERTY') return property;
    return state;
  },
  budget(state = [], {type, budget}) {
    if (type === 'SET_BUDGET') return budget;
    return state;
  },
  detailedAccount(state = [], {type, account}) {
    if (type === 'SET_DETAILED_ACCOUNT') return account;
    return state;
  },
  years(state = [], {type, years}) {
    if (type === 'SET_YEARS') return years;
    return state;
  },
  year(state = currentYear, {type, year}) {
    if (type === 'SET_YEAR') return year;
    return state;
  },
  imports(state = [], {type, imports}) {
    if (type === 'SET_IMPORTS') return imports;
    return state;
  },
  playground(state = [], {type, playground}) {
    if (type === 'SET_PLAYGROUND') return playground;
    return state;
  }
});