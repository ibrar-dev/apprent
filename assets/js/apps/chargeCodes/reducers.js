import {combineReducers} from 'redux';

export default combineReducers({
  chargeCodes(state = [], {type, chargeCodes}){
    if (type === 'SET_CHARGE_CODES') return chargeCodes;
    return state;
  }
});