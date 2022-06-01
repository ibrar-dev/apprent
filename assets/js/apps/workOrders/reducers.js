import {combineReducers} from "redux";

const reducers = {
  techs(state = [], {type, techs}) {
    if (type === "SET_TECHS") return techs;
    return state;
  },
  admins(state = [], {type, admins}) {
    if (type === "SET_ADMINS") return admins;
    return state;
  },
  vendors(state = [], {type, vendors}) {
    if (type === "SET_VENDORS") return vendors;
    return state;
  },
  vendorCategories(state = [], {type, categories}) {
    if (type === "SET_VENDOR_CATEGORIES") return categories;
    return state;
  },
  categories(state = [], action) {
    if (action.type === "SET_CATEGORIES") return action.categories;
    return state;
  },
  subcategories(state = [], action) {
    if (action.type === "SET_SUBCATEGORIES") return action.subcategories;
    return state;
  },
  workOrders(state = {
    open: [], completed: [], canceled: [], in_progress: [], on_hold: [], outsourced: [],
  }, {type, workOrders}) {
    if (type === "SET_WORK_ORDERS") return workOrders;
    return state;
  },
  openWorkOrder(state = null, {type, order}) {
    switch (type) {
      case "OPEN_WORK_ORDER":
        return order;
      default:
        return state;
    }
  },
  options(state = [], action) {
    if (action.type === "SET_OPTIONS") return action.options;
    return state;
  },
  searchResults(state = {}, {type, results}) {
    if (type === "SET_SEARCH_RESULTS") return results;
    return state;
  },
  skeleton(state = false, {type, value}) {
    if (type === "SET_SKELETON") return value;
    return state;
  },
  newOrders(state = {}, {type, orders}) {
    if (type === "SET_NEW_ORDERS") return orders;
    return state;
  },
  orderData(state = null, {type, data}) {
    if (type === "SET_ORDER_DATA") return data;
    return state;
  },
};
export default combineReducers(reducers);
