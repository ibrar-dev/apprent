import {combineReducers} from "redux";
import moment from 'moment';

const reducers = {
  batches(state = [], {type, batches}) {
    if (type === "SET_BATCHES") return batches;
    return state;
  },
  dateFilters(state = {startDate: moment().days(-10), endDate: moment()}, {type, value}) {
    if (type === "SET_DATE_FILTERS") return value;
    return state;
  },

  payments(state = [], {type, payments}) {
    if (type === 'SET_PAYMENTS') return payments;
    return state;
  },
  report(state = [], {type, reportData}) {
    if (type === 'SET_DATA') return reportData;
    return state;
  },
  accounts(state = [], {type, accounts}) {
    if (type === 'SET_ACCOUNTS') return accounts;
    return state;
  },
  paymentImage(state = null, {type, paymentImage}) {
    if (type === 'SET_PAYMENT_IMAGE') return paymentImage;
    return state;
  },
  vendors(state = [], {type, vendors}){
    if(type === 'SET_VENDORS') return vendors;
    return state;
  },
  vendorCategories(state = [], {type, vendor_categories}){
    if(type === 'SET_VENDOR_CATEGORIES') return vendor_categories;
    return state;
  },
  payment(state = {}, {type, payment}) {
    if (type === 'SET_PAYMENT') return payment;
    return state;
  }
};
export default combineReducers(reducers)
