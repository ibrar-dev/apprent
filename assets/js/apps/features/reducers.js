import {combineReducers} from "redux"
const reducers = {
  features(state = [], {type, features}) {
    if (type === 'SET_FEATURES') return features;
    return state;
  },
  floorPlans(state = [], {type, floorPlans}) {
    if (type === 'SET_FLOOR_PLANS') return floorPlans;
    return state;
  },
  mode(state = 'floorPlans', {type, mode}) {
    if (type === 'SET_MODE') return mode;
    return state;
  },
  properties(state = [], {type, properties}) {
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  },
  units(state = [], {type, units}) {
    if (type === 'SET_UNITS') return units;
    return state;
  },
  property(state = {}, {type, property}) {
    if (type === 'SET_PROPERTY') return property;
    return state
  },
  chargeCodes(state = [], {type, chargeCodes}) {
    if (type === 'SET_CHARGE_CODES') return chargeCodes;
    return state;
  }
};
export default combineReducers(reducers);
