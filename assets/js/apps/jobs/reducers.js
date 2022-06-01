import {combineReducers} from "redux";

let reducers = {
  jobTypes(state = {}, {type, jobTypes}) {
    if (type === 'SET_JOB_TYPES') return jobTypes;
    return state;
  },
  jobs(state = [], {type, jobs}) {
    if (type === 'SET_JOBS') return jobs;
    return state;
  }
};
let reducer = combineReducers(reducers);
export default reducer;
