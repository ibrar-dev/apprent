import {combineReducers} from 'redux';
import moment from "moment";

const reducers = {
  documents(state=[], {type, adminDocuments}){
    if(type === 'SET_ADMIN_DOCUMENTS') return adminDocuments;
    return state;
  },
  events: (state = [], {type, events})=>{
    switch(type){
      case 'SET_EVENTS':
        const eventMap = {};
        Object.keys(events).forEach(eventType => {
          const list = events[eventType];
          list.forEach(event => {
            const date = event.date;
            if (!eventMap[date]) eventMap[date] = [];
            eventMap[date].push({type: eventType, ...event});
          });
        });
        return eventMap;
      default:
        return state
    }
  },
  maintenanceSnapshot: (state = [], {type, stats})=> {
    if (type === 'SET_MAINTENANCE_SNAPSHOT') {
      let newStats = [];
      stats.forEach(p => {
        if (p.name === 'Dasmen Sandbox') return p;
        if (p.created >= 1 || p.completed >= 1) return newStats.push(p);
        // if (p.completed.map(i => {i.completed >= 1})) return newStats.push(p);
        // if (p.completed.map(i => {i.callbacks >= 1})) return newStats.push(p);
      });
      return newStats;
    }
    return state;
  },
  propertyReport: (state = [], {type, data}) => {
    if (type === 'SET_PROPERTY_REPORT') return data;
    return state;
  },
  propertyDeliquency: (state = {}, {type, data}) => {
    if (type === 'SET_PROPERTY_DELIQUENCY') return data;
  return state;
  },
  specificProperties: (state = [], {type, reportData}) => {
    if (type === 'SET_SPECIFIC_PROPERTIES') return reportData;
    return state;
  },
  properties(state = [], {type, properties}) {
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  },
  property(state = {}, {type, property}) {
    if (type === 'SET_PROPERTY') return property;
    return state;
  },
  fetching(state = false, {type, status}) {
    if (type === 'SET_FETCHING') return status;
    return state;
  }
};
const reducer = combineReducers(reducers);
export default reducer
