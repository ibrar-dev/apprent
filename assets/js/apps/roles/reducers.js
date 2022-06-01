import {combineReducers} from 'redux';

const reducers = {
  roleTree(state = [], {type, roleTree}) {
    if (type === 'SET_ROLE_TREE') return roleTree;
    return state;
  },
  roles(state = [], {type, roles}) {
    if (type === 'SET_ROLES') return roles;
    return state;
  }
};

export default combineReducers(reducers)
