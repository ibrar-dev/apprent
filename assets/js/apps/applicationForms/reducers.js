import {combineReducers} from 'redux';

const reducers = {
  applications(state = [], {type, applications}) {
    if (type === 'SET_APPLICATIONS') return applications;
    return state;
  },
  application(state = null, {type, application}) {
    if (type === 'SET_APPLICATION') return application;
    return state;
  },
  lease(state = {}, {type, lease}) {
    if (type === 'SET_LEASE') return lease;
    return state;
  },
  units(state = [], {type, units}) {
    if (type === 'SET_UNITS') return units;
    return state;
  },
  unitInfo(state = {}, {type, unitInfo}) {
    if (type === 'SET_UNIT_INFO') return unitInfo;
    return state;
  },
  chargeCodes(state = [], {type, chargeCodes}) {
    if (type === 'SET_CHARGE_CODES') return chargeCodes;
    return state;
  },
  applicant(state = null, {type, applicant}) {
    if (type === 'SET_APPLICANT') return applicant;
    return state;
  },
  availableUnits(state = [], {type, availableUnits}) {
    if (type === 'SET_AVAILABLE_UNITS') return availableUnits;
    return state;
  },
  step(state = 0, {type}) {
    switch (type) {
      case 'STEP_FORWARD':
        return state + 1;
      case 'STEP_BACK':
        return state - 1;
      default:
        return state;
    }
  },
  properties(state = [], {type, properties}) {
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  },
  property(state = {}, {type, property}) {
    if (type === 'SET_PROPERTY') return property;
    return state;
  },
  credentialsList(state = {}, {type, credentials}) {
    if (type === 'SET_CREDENTIALS_LIST') return credentials;
    return state;
  }
};

export default combineReducers(reducers)
