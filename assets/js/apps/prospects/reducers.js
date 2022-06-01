import {combineReducers} from "redux";

const reducers = {
  properties(state = [], {type, properties}) {
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  },
  prospects(state = [], {type, prospects}) {
    if (type === 'SET_PROSPECTS') return prospects;
    return state;
  },
  agents(state = [], {type, agents}) {
    if (type === 'SET_AGENTS') return agents;
    return state;
  },
  trafficSources(state = [], {type, trafficSources}) {
    if (type === 'SET_TRAFFIC_SOURCES') return trafficSources;
    return state;
  },
  showings(state = [], {type, showings}) {
    if (type === 'SET_SHOWINGS') return showings;
    return state;
  },
  openings(state = [], {type, openings}) {
    if (type === 'SET_OPENINGS') return openings;
    return state;
  },
  property(state = {}, {type, property}) {
    if (type === 'SET_PROPERTY') return property;
    return state;
  }
};

export default combineReducers(reducers);