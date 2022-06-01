import {combineReducers} from "redux";

const reducers = {
  banks(state = [], {type, banks}) {
    if (type === 'SET_BANKS') return banks;
    return state;
  },
  damages(state = [], {type, damages}) {
    if (type === 'SET_DAMAGES') return damages;
    return state;
  },
  moveOutReasons(state = [], {type, moveOutReasons}) {
    if (type === 'SET_MOVE_OUT_REASONS') return moveOutReasons;
    return state;
  },
  credentialSets(state = 'not loaded', {type, credentialSets}) {
    if (type === 'SET_CREDENTIAL_SETS') return credentialSets;
    return state;
  },
  accounts(state = [], {type, accounts}) {
    if (type === 'SET_ACCOUNTS') return accounts;
    return state;
  }
};

export default combineReducers(reducers);