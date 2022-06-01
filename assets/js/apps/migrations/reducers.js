import {combineReducers} from "redux";

let reducers = {
  migrations(state = [], {type, migrations}) {
    if (type === 'SET_MIGRATIONS') return migrations;
    return state;
  }
};
let reducer = combineReducers(reducers);
export default reducer;
