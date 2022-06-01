import {combineReducers} from "redux"
const reducers = {
  properties: (state = [], action) => {
    switch (action.type) {
      case 'SET_PROPERTIES':
        return action.properties;
      default:
        return state
    }
  },
  paymentReport(state = [], {type, paymentReport}){
    if(type === 'SET_PAYMENT_REPORT') return paymentReport;
    return state;
  },
  property(state = {}, {type, property}) {
    if (type === 'SET_PROPERTY') return property;
    return state;
  },
  report(state = '', {type, report}) {
    if (type === 'SET_REPORT') return report;
    return state;
  },
  residentsData(state=[], {type, residentsData}){
    if(type === 'SET_RESIDENT_DIRECTORY') return residentsData;
    return state;
  },
  availability(state=[], {type, availability}){
    if(type === 'SET_AVAILABILITY_DATA') return availability;
    return state;
  },
  payers(state = [], {type, payers}) {
    if (type === 'SET_PAYERS') return payers;
    return state;
  },
  newBoxScore(state={}, {type, new_box_score}){
    if(type === 'SET_NEW_BOX_SCORE') return new_box_score;
    return state;
  },
  unitStatus(state = [], {type, unit_status}){
    if(type === 'SET_UNIT_STATUS') return unit_status;
    return state;
  },
  // units(state = [], {type, units}) {
  //   if (type === 'SET_UNITS') return units;
  //   return state;
  // },
  reportData(state = [], {type, reportData}) {
    if (type === 'SET_DATA') return reportData;
    return state;
  },
  skeleton(state = false, {type, skeleton}) {
    if (type === 'SET_SKELETON') return skeleton;
    return state;
  },
  mode(state = "all", {type, mode}) {
    if (type === 'SET_MODE') return mode;
    return state;
  },
  residentActivity(state = {}, {type, residentActivity}){
    if(type === 'SET_BOX_SCORE') return residentActivity;
    return state;
  },
  activityDate(state = {}, {type, activityDate}){
    if(type === 'SET_ACTIVITY_DATE') return activityDate;
    return state;
  },
  detailed(state = null, {type, data}) {
    if (type === 'SET_DETAILED_DATA') return data;
    return state;
  }
};

export default combineReducers(reducers);
