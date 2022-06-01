import {combineReducers} from "redux";

let reducers = {
  properties(state = [], {type, properties}) {
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  },
  stocks(state = [], {type, stocks}) {
    if (type === 'SET_STOCKS') return stocks;
    return state;
  },
  tech(state = null, {type, tech}) {
    if (type === 'SET_TECH') return tech;
    return state;
  },
  assignments(state = {}, {type, assignments}) {
    if (type === 'SET_ASSIGNMENTS') return assignments;
    return state;
  },
  techs(state = [], {type, techs}) {
    if (type === 'SET_TECHS') return techs;
    return state;
  },
  filter(state = '', {type, filter}) {
    if (type === 'SET_FILTER') return filter;
    return state;
  },
  orders(state = {}, {type, orders}) {
    if (type === 'SET_ORDERS') {
      const s = {};
      if (orders.length >= 1) orders.forEach(o => s[o.id] = o);
      return s;
    }
    return state;
  },
  categories(state = [], {type, categories}) {
    if (type === 'SET_CATEGORIES') return categories;
    return state;
  },
  mode(state = null, {type, mode}) {
    if (type === 'SET_MODE') return mode;
    return state;
  },
  history(state = [], {type, stats}) {
    if (type === 'SET_HISTORY') return stats;
    return state;
  },
  searchResults(state = {}, {type, results}) {
    if (type === 'SET_SEARCH_RESULTS') return results;
    return state;
  },
};

let reducer = combineReducers(reducers);
export default reducer