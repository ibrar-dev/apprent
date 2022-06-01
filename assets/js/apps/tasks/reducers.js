import {combineReducers} from "redux";

let reducers = {
  tasks(state = [], {type, tasks}) {
    if (type === 'SET_TASKS') return tasks;
    return state;
  }
};

let reducer = combineReducers(reducers);
export default reducer