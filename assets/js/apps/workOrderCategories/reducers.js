import {combineReducers} from "redux";

const reducers = {
  categories(state = [], {type, categories}) {
    if (type === 'SET_CATEGORIES') return categories;
    return state;
  }
};

export default combineReducers(reducers);