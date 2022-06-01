import {combineReducers} from 'redux';
import {getCookie} from "../../utils/cookies";

export default combineReducers({
  propertiesSelected(state = getCookie("multiPropertySelector") || [], {type, propertiesSelected}){
    if (type === 'SET_PROPERTIES_SELECTED') return propertiesSelected;
    return state;
  },
  properties(state = [], {type, properties}){
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  },
  property(state = {id:-1}, {type, property}) {
    if (type === 'SET_PROPERTY') return property;
    return state;
  },
  approvals(state = [], {type, approvals}) {
    if (type === 'SET_APPROVALS') return approvals;
    return state
  },
  payees(state = [], {type, payees}) {
    if (type === 'SET_PAYEES') return payees;
    return state;
  },
  approvers(state = [], {type, approvers}) {
    if (type === 'SET_APPROVERS') return approvers;
    return state;
  },
  approval(state = {}, {type, approval}) {
    if (type === 'SET_APPROVAL') return approval;
    return state;
  },
  attachments(state = [], {type, attachments}) {
    if(type === "SET_ATTACHMENT") return attachments;
    return state;
  },
  adminData(state = {}, {type, adminData}) {
    if (type === "SET_ADMIN_DATA") return adminData;
    return state;
  },
  admin(state = null, {type, admin}) {
    if (type === "SET_ADMIN") return admin;
    return state;
  },
  everyone(state = [], {type, everyone}) {
    if (type === "SET_EVERYONE") return everyone;
    return state;
  },
  chart_data(state = {}, {type, data}){
    if(type === "SET_CHART_DATA") return data;
    return state;
  },
  accountingCategories(state = [], {type, categories}) {
    if (type === "SET_ACCOUNTING_CATEGORIES") return categories;
    return state;
  },
  moneySpent(state = {}, {type, spent}) {
    if (type === "SET_MONEY_SPENT") return spent;
    return state;
  }
});
