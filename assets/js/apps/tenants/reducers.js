import {combineReducers} from 'redux';

export default combineReducers({
  batchIDS(state = [], {type, batch}){
    if(type === 'SET_BATCH_IDS') return batch;
    return state;
  },
  propertyTemplates(state = [],{type, data}){
    if (type === 'SET_PROPERTY_TEMPLATES') return data;
    return state;
  },
  tenants(state = [], {type, tenants}){
    if (type === 'SET_TENANTS') return tenants;
    return state;
  },
  rewards(state = {}, {type, awards}) {
    if (type === 'SET_TENANT_AWARD_HISTORY') return {awards};
    return state;
  },
  awardTypes(state = {}, {type, types}){
    if (type === 'SET_TENANT_AWARD_TYPES') {
      return {types}};
    return state;
  },
  purchaseHistory(state = {}, {type, purchases}){
    if (type === 'SET_TENANT_PURCHASE_HISTORY') return {purchases};
    return state;
  },
  prizes(state = {}, {type, prizes}){
    if (type === 'SET_TENANT_PRIZES') return {prizes};
    return state;
  },
  points(state = 0, {type, points}){
    if (type === 'SET_TENANT_POINTS') return points;
    return state;
  },
  tenant(state = null, {type, tenant}) {
    if (type === 'VIEW_TENANT') return tenant;
    return state;
  },
  account(state = null, {type, account}) {
    if (type === 'SET_ACCOUNT') return account;
    return state;
  },
  filter(state = '', {type, filter}) {
    if (type === 'SET_FILTER') return filter;
    return state;
  },
  agents(state = [], {type, agents}){
    if (type === 'SET_AGENTS') return agents;
    return state;
  },
  accounts(state = [], {type, accounts}) {
    if (type === 'SET_ACCOUNTS') return accounts;
    return state;
  },
  chargeCodes(state = [], {type, chargeCodes}) {
    if (type === 'SET_CHARGE_CODES') return chargeCodes;
    return state;
  },
  properties(state = [], {type, properties}) {
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  },
  property(state = {}, {type, property}) {
    if (type === 'SET_PROPERTY') return property;
    return state;
  },
  units(state = [], {type, units}) {
    if (type === 'SET_UNITS') return units;
    return state;
  },
  workOrders(state = [], {type, workOrders}) {
    if (type === 'SET_WORK_ORDERS') return workOrders;
    return state;
  },
  moveOutReasons(state = [], {type, moveOutReasons}) {
    if (type === 'SET_MOVE_OUT_REASONS') return moveOutReasons;
    return state;
  },
  filters(state = {}, {type, filters}) {
    if (type === 'SET_FILTERS') return filters;
    return state;
  },
  damages(state = [], {type, damages}) {
    if (type === 'SET_DAMAGES') return damages;
    return state;
  }
});
