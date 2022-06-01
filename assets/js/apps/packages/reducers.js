import {combineReducers} from 'redux';

 let reducers = {
     packages(state = [], action) {
         switch (action.type) {
             case 'SET_PACKAGES':
                 return action.packages;
             case 'UPDATE_PACKAGES':
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
     tenants(state = [], action) {
         switch (action.type){
             case 'SET_TENANTS':
                 return action.tenants;
             default:
                 return state
         }
     }
 };
 let reducer = combineReducers(reducers);
 export default reducer