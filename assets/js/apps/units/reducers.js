import {combineReducers} from "redux"

let reducers = {
  units(state = [], {type, units}) {
    if (type === 'SET_UNITS') return units;
    return state;
  },
  unit(state = null, {type, unit}) {
    if (type === 'VIEW_UNIT') return unit;
    return state;
  },
  features(state = [], {type, unitTypes}) {
    if (type === 'SET_FEATURES') return unitTypes;
    return state;
  },
  floorPlans(state = [], {type, floorPlans}) {
    if (type === 'SET_FLOOR_PLANS') return floorPlans;
    return state;
  },
  filters(state = {}, {type, filter, value, predicate}) {
    switch (type) {
      case 'ADD_FILTER':
        state[filter] = {value, predicate};
        return state;
      case 'REMOVE_FILTER':
        delete state[filter];
        return state;
      default:
        return state
    }
  },
  property(state = null, {type, property}) {
    if (type === 'SET_PROPERTY') return property;
    return state;
  },
  properties(state = [], {type, properties}) {
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  },
  skeleton(state = false, {type, skeleton}) {
    if (type === 'SET_SKELETON') return skeleton;
    return state;
  }
};
export default combineReducers(reducers)
