import {combineReducers} from 'redux';

const reducers = {
  stats(state = {}, {type, stats}) {
    if (type === 'SET_STATS') return stats;
    return state;
  },
  properties(state = [], {type, properties}) {
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  }
};
const reducer = combineReducers(reducers);
export default reducer
