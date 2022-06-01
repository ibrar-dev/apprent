import {combineReducers} from 'redux';

export default combineReducers({
  properties(state = [], {type, properties}) {
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  },
  property(state = {}, {type, property}) {
    if (type === 'SET_PROPERTY') return property;
    return state;
  },
  residents(state = [], {type, residents}) {
    if (type === 'SET_RESIDENTS') return residents;
    return state;
  },
  letters(state = [], {type, letters}) {
    if (type === 'SET_LETTERS') return letters;
    return state;
  },
  selectedResidents(state = [], {type, selected}) {
    if (type === 'SET_SELECTED') return selected;
    return state;
  },
  recurringLetters(state = [], {type, letters}) {
    if (type === 'SET_RECURRING_LETTERS') return letters;
    return state;
  },
  admins(state = [], {type, admins}) {
    if (type === 'SET_ADMINS') return admins;
    return state;
  },
  previewTenants(state = [], {type, previewTenants}){
    if (type === 'PREVIEW_TENANTS') return previewTenants;
    return state;
  },
})