import {combineReducers} from "redux";

let reducers = {
  exports(state = [], {type, exports}) {
    if (type === 'SET_EXPORTS') return exports;
    return state;
  }
};
let reducer = combineReducers(reducers);
export default reducer;
