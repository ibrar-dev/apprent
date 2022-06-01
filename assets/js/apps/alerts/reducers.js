import {combineReducers} from 'redux';

export default combineReducers({
  alerts(state = [], {type, alerts}){
    if (type === 'SET_ALERTS') return alerts;
    return state;
  },
  readAlerts(state = [], {type, readAlerts}){
    if (type === 'SET_READ_ALERTS') return readAlerts;
    return state;
  },
});