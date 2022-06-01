import {combineReducers} from 'redux';

export default combineReducers({
  templates(state = [], {type, templates}){
    if (type === 'SET_TEMPLATES') return templates;
    return state;
  },
  properties(state = [], {type, properties}){
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  },
  report(state = {}, {type, report}) {
    if (type === 'SET_REPORT') return report;
    return state;
  },
  reportType(state = {}, {type, report}) {
    if (type === 'SET_REPORT_TYPE') return report;
    return state;
  }
});