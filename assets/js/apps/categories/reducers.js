import {combineReducers} from "redux";

let reducers = {
	categories(state = [], {type, categories}) {
		if (type === 'SET_CATEGORIES') return categories;
		return state;
	},
}

let reducer = combineReducers(reducers);
export default reducer