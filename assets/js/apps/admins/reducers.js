import {combineReducers} from "redux"

let reducers = {
  admins(state = [], action) {
    switch (action.type) {
      case 'SET_ADMINS':
        return action.admins;
      case 'REMOVE_ADMIN':
        return state.filter(a => a.id !== action.admin.id);
      case 'ADD_ADMIN':
        return state.concat(action.admin);
      case 'UPDATE_ADMIN':
        return state.map((a) => {
          if (a.id === action.newVals.id) {
            return action.newVals
          }
          return a
        });
      default:
        return state
    }
  },
  filters(state = {}, action) {
    switch (action.type) {
      case 'ADD_FILTER':
        state[action.filter] = {value: action.value, predicate: action.predicate};
        return state;
        break;
      case 'REMOVE_FILTER':
        delete state[action.filter];
        return state;
        break;
      default:
        return state
    }
  },
  addresses(state = [], action) {
    switch (action.type) {
      case 'SET_ADDRESSES':
        return action.addresses;
        break;
      case 'ADD_ADDRESS':
        return state.concat(action.address);
      default:
        return state
    }
  },
  entities(state = [], {type, entities}) {
    if (type === 'SET_ENTITIES') return entities;
    return state;
  },
  activeAdmin(state = {}, {type, activeAdmin}) {
    if (type === 'SET_ACTIVE_ADMIN') return activeAdmin;
    return state;
  },
  admin(state = {}, {type, admin}) {
    if (type === 'SET_ADMIN') return admin;
    return state;
  },
  actions(state = [], {type, actions}) {
    if (type === 'SET_ACTIONS') return actions;
    return state;
  },
  insightSubscriptions(state = [], {type, actions}) {
    if (type === 'SET_INSIGHT_SUBSCRIPTIONS') return actions;
    return state;
  },
};
let reducer = combineReducers(reducers);
export default reducer
