import {combineReducers} from 'redux';

const reducers = {
  applications(state = [], {type, applications}) {
    if (type === 'SET_APPLICATIONS') return applications;
    return state;
  },
  properties(state = [], {type, properties}) {
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  },
  property(state = {}, {type, property}) {
    if (type === 'SET_PROPERTY') return property;
    return state;
  },
};

export default combineReducers(reducers)
