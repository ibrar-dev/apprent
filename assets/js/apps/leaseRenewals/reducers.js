import {combineReducers} from 'redux';
import JsPDF from 'jspdf';
import moment from "moment";

export default combineReducers({
  properties(state = [], {type, properties}) {
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  },
  property(state = {}, {type, property}) {
    if (type === 'SET_PROPERTY') return property;
    return state;
  },
  periods(state = [], {type, periods}) {
    if (type === 'SET_BATCH_PERIODS') return periods;
    return state;
  },
  report(state = {}, {type, report}) {
    if (type === 'SET_REPORT') return report;
    return state;
  },
  packages(state = [
    {min: 7, max: 7, base: 'Current Rent', amount: null, dollar: false, index: 0},
    {min: 8, max: 9, base: 'Current Rent', amount: null, dollar: false, index: 1},
    {min: 10, max: 11, base: 'Current Rent', amount: null, dollar: false, index: 2},
    {min: 12, max: 14, base: 'Current Rent', amount: null, dollar: false, index: 3}
    ], {type, packages}) {
    switch (type) {
      case 'SET_PACKAGES':
        return packages;
      case 'CLEAR_PACKAGES':
        return state;
      // case 'ADD_PACKAGE':
      //   let newState = state;
      //   let nextIndex = newState.length;
      //   newState.push({min: null, max: null, base: 'Market Rent', amount: null, dollar: true, index: nextIndex});
      //   return newState;
      default:
        return state;
    }
  },
  validation(state = {loading: false}, {type, validation}) {
    if (type === 'SET_VALIDATION') return validation;
    return state;
  },
  period(state = {}, {type, period}) {
    if (type === 'SET_PERIOD') return period;
    return state;
  },
  letters(state = [], {type, letters}) {
    //FUNCTIONS HERE TO GENERATE EACH LETTER AND UPLOAD THEM TO THE SERVER
    // if (type === 'SET_LETTERS') return letters;
    if (type === 'SET_LETTERS') {
      let pdf = new JsPDF('p', 'pt', 'a4');
      pdf.fromHTML(letters[0], {'width': 7.5});
      pdf.save('TESTED PDF')
    }
    return state;
  },
  fetching(state = false, {type, data}) {
    if (type === "SET_FETCHING") return data;
    return state;
  },
  leases(state = [], {type, leases}){
    if(type === 'SET_LEASES') return leases;
    return state;
  },
  dates(state = {startDate: moment().startOf('month'), endDate: moment()}, {type, dates}){
    if(type === 'SET_DATES') return dates;
    return state;
  }
})