import {combineReducers} from "redux"

const reducers = {
  devices(state = [], {type, devices}) {
    if (type === 'SET_DEVICES') return devices;
    return state;
  },
  properties(state = [], {type, properties}) {
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  }
};
export default combineReducers(reducers);
