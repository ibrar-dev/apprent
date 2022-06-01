import {combineReducers} from 'redux';

export default combineReducers({
  accounts(state = [], {type, accounts}) {
    if (type === 'SET_ACCOUNTS') return accounts;
    return state;
  },
  lease(state = {}, {type, lease}) {
    if (type === 'SET_LEASE') return lease;
    return state;
  },
  availableUnits(state = [], {type, availableUnits}) {
    if (type === 'SET_AVAILABLE_UNITS') return availableUnits;
    return state;
  },
  periods(state = [], {type, periods}) {
    if (type === 'SET_BATCH_PERIODS') return periods;
    return state;
  },
  packages(state = {}, {type, packages}) {
    if(type === 'SET_LEASE_PACKAGES') return packages;
    return state;
  },
  defaultLeaseCharges(state = [], {type, default_lease_charges}){
    if(type === 'SET_DEFAULT_LEASE_CHARGES') return default_lease_charges;
    return state;
  },
  rent(state = null, {type, rent}){
    if(type === 'SET_RENT') return rent;
    return state;
  },
  pack(state = {}, {type, pack}){
    if(type === 'SET_PACKAGE') return pack;
    return state;
  }
});
