import {combineReducers} from "redux";

const reducers = {
  trafficSources(state = [], {type, trafficSources}) {
    if (type === 'SET_TRAFFIC_SOURCES') return trafficSources;
    return state;
  }
};

let reducer = combineReducers(reducers);
export default reducer