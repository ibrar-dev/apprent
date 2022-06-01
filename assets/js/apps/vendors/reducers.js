import {combineReducers} from 'redux';

 let reducers = {
     vendors(state = [], action) {
         switch (action.type) {
             case 'SET_VENDORS':
                 return action.vendors;
             case 'REMOVE_VENDORS':
                 return state.filter(a => a.id !== action.admin.id);
             case 'ADD_VENDORS':
                 return state.concat(action.admin);
             case'VIEW_VENDOR':
                 return action.vendors;
             case 'UPDATE_VENDORS':
                 return state.map((a) => {
                     if (a.id === action.newVals.id) {
                         return action.newVals
                     }
                     return a
                 });
             default:
                 return state
         }

     },
     properties(state = [], {type, properties}) {
         if (type === 'SET_PROPERTIES') return properties;
         return state;
     },
     orders(state = null, action) {
         switch (action.type) {
             case 'SET_VENDOR_ORDERS':
                 return action.orders;
             default:
                 return state
         }
     },
     categories(state = [], action) {
         switch (action.type) {
             case 'SET_VENDOR_CATEGORIES':
                 return action.categories;
             default:
                 return state
         }
     }
 };
 let reducer = combineReducers(reducers);
 export default reducer