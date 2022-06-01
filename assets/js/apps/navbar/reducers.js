import {combineReducers} from 'redux';

const reducers = {
  admin(state = {}, {type, admin}) {
    switch (type) {
      case 'SET_ADMIN':
        return admin;
      default:
        return state
    }

  },
};

export default combineReducers(reducers);