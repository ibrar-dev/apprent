import {combineReducers} from "redux";

const reducers = {
  showings(state = [], {type, showings}) {
    if (type === 'SET_SHOWINGS') return showings;
    return state;
  },
  openings(state = [], {type, openings}) {
    if (type === 'SET_OPENINGS') return openings;
    return state;
  },
  closures(state = [], {type, closures}) {
    if (type === 'SET_CLOSURES') return closures;
    return state;
  },
  property(state = {}, {type, property}) {
    if (type === 'SET_PROPERTY') return property;
    return state;
  }
};

export default combineReducers(reducers);