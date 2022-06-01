import {combineReducers} from 'redux';

const reducers = {
    vendors(state = [], {type, vendors}) {
        if(type === "SET_VENDORS") return vendors;
        return state;
    },
    admins(state = [], {type, admins}) {
        if(type === "SET_ADMINS") return admins;
        return state;
    },
    properties(state = [], {type, properties}) {
        if(type === "SET_PROPERTIES") return properties;
        return state;
    },
    items(state = [], {type, items}){
        if(type === "SET_ITEMS") return items;
        return state;
    },
    po_rules(state=[], {type, rules}){
        if(type === "SET_RULES") return rules;
        return state;
    },
    treeData(state=[], {type, treeData}){
        if(type === "SET_TREE_DATA") return treeData;
        return state;
    }
};

export default combineReducers(reducers);