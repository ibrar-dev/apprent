import {combineReducers} from 'redux';

const reducers = {
  sidebar(state = null, {type, sidebar}) {
    if (type === 'SET_SIDEBAR') return sidebar;
    return state;
  },
  role(state = window.roles[0], {type, role}) {
    if (type === 'SET_ROLE') return role;
    return state;
  },
  alerts(state = null, {type, unread}) {
    if (type === 'SET_UNREAD') return unread;
    return state;
  }
};

export default combineReducers(reducers);