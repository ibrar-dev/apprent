import {combineReducers} from "redux"
let reducers = {
  properties: (state = [], {type, properties})=>{
    switch(type){
      case 'SET_PROPERTIES':
        return properties;
      default:
        return state
    }
  },
  entities: (state = [], {type, entities})=>{
    switch(type){
      case 'SET_ENTITIES':
        return entities;
      default:
        return state
    }
  }
};
let reducer = combineReducers(reducers);
export default reducer
