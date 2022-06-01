import {combineReducers} from "redux"

let reducers = {
  actions(state = [], {type, actions}) {
    if (type === 'SET_ACTIONS') return actions;
    return state;
  }
};
let reducer = combineReducers(reducers);
export default reducer;
