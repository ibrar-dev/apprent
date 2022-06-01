import {combineReducers} from "redux"
const reducers = {
  closings(state = [], {type, closings}) {
    if (type === 'SET_CLOSINGS') return closings;
    return state;
  },
  property(state = null, {type, property}) {
    if (type === 'SET_PROPERTY') return property;
    return state;
  },
  properties(state = [], {type, properties}) {
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  }
};
export default combineReducers(reducers)
