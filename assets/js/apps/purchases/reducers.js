import { combineReducers } from "redux";

const reducers = {
    purchases(state = [], { type, purchases }) {
        if (type === 'SET_PURCHASES') return purchases;
        return state;
    }
};

export default combineReducers(reducers);