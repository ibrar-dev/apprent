import {combineReducers} from "redux";

const reducers = {
  prizes(state = [], {type, prizes}) {
    if (type === 'SET_PRIZES') return prizes;
    return state;
  },
  types(state = [], {type, types}) {
    if (type === 'SET_TYPES') return types;
    return state;
  },
};

export default combineReducers(reducers);