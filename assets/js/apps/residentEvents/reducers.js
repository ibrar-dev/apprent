import {combineReducers} from 'redux';

export default combineReducers({
  properties(state = [], {type, properties}){
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  },
  events(state = [], {type, events}){
    if (type === 'SET_EVENTS') {
      return events;
    }
    return state;
  },
  property: (state = null, {type, property}) => {
    switch(type){
      case 'OPEN_PROPERTY':
        return property;
      default:
        return state
    }
  },
  showEvent(state = null, {type, event}) {
    if (type === 'SET_EVENT') return event;
    return state;
  }
});