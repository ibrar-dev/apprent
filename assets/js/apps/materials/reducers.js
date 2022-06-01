import {combineReducers} from "redux";
let reducers = {
  techProfile(state = {}, {type, tech}) {
    if (type === 'SET_TECH') return tech;
    return state;
  },
  properties(state = [], {type, properties}) {
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  },
  stocks(state = [], {type, stocks}) {
    if (type === 'SET_STOCKS') return stocks;
    return state;
  },
  logs(state = [], {type, logs}) {
    if (type === 'SET_LOGS') return logs;
    return state;
  },
  report(state = false, {type, value}) {
    if (type === 'SET_REPORT') return value;
    return state;
  },
  stock(state = null, {type, stock}) {
    if (type === 'SET_STOCK') return stock;
    return state;
  },
  materials(state = [], {type, materials}) {
    if (type === 'SET_MATERIALS') return materials;
    return state
  },
  shop_user(state = {}, {type, user })  {
    if (type === "SET_SHOP_USER") return user;
    return state
  },
  shop_materials(state = [], {type, materials })  {
      if (type === "SET_SHOP_MATERIALS") return materials;
      return state
  },
  shop_cart(state = [], {type, cart })  {
      if (type === "SET_SHOP_CART") return cart;
      return state
  },
  tool_box(state = [], {type, tools })  {
      if (type === "SET_TOOL_BOX") return tools;
      return state
  },
  filter(state = '', {type, filter}) {
    if (type === 'SET_FILTER') return filter;
    return state;
  },
  types(state = [], {type, types}) {
    if (type === 'SET_TYPES') return types;
    return state;
  },
  materialCart(state = [], {type, material}) {
    if (type === 'ADD_CART') {
      let newState = state;
      newState.push(material);
      return newState;
    }
    if (type === 'REMOVE_CART') {
      let newState = state;
      newState.splice(state.indexOf(material), 1);
      return newState;
    }
    return state;
  },
  materialInfo(state = {}, {type, material}) {
    if (type === 'SET_MATERIAL_INFO') return material;
    return state;
  },
  timeoutTime(state = 300, {type, time}) {
    if (type === 'RESET_TIME') return time;
    return state;
  }
};
let reducer = combineReducers(reducers);
export default reducer
