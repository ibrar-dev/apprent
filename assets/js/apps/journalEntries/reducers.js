import {combineReducers} from "redux";

let reducers = {
  journalPages(state = [], {type, journalPages}) {
    if (type === 'SET_JOURNAL_PAGES') return journalPages;
    return state;
  },
  activeJournal(state = [], {type, activeJournal}) {
    if (type === 'SET_ACTIVE_JOURNAL') return activeJournal;
    return state;
  },
  accounts(state = [], {type, accounts}) {
    if (type === 'SET_ACCOUNTS') return accounts;
    return state;
  },
  properties(state = [], {type, properties}) {
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  },
  editing(state = null, {type, entry}) {
    if (type === 'SET_EDIT_ENTRY') return entry;
    return state;
  }
};
let reducer = combineReducers(reducers);
export default reducer;
