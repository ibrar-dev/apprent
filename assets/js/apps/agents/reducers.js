import {combineReducers} from "redux"
let reducers = {
  agents: (state = [], action)=>{
    switch(action.type){
      case 'SET_AGENTS':
        return action.agents;
      case 'REMOVE_AGENT':
        return state.filter(p=> p.id !== action.agent.id);
      case 'ADD_AGENT':
        return state.concat(action.agent);
      case 'UPDATE_AGENT':
        return state.map((p)=>{
          if(p.id === action.newVals.id){
            return action.newVals
          }
          return p
        });
      default:
        return state
    }
  },
  openAgent: (state = null, action)=>{
    switch(action.type){
      case 'OPEN_AGENT':
        return action.openAgent;
      case 'CLOSE_AGENT':
        return null;
      case 'EDIT_AGENT':
        return {...state, [action.field]: action.value};
      default:
        return state
    }
  },
  filters: (state = {}, action)=>{
    switch(action.type){
      case 'ADD_FILTER':
        state[action.filter] = {value: action.value, predicate: action.predicate};
        return state;
        break;
      case 'REMOVE_FILTER':
        delete state[action.filter];
        return state;
        break;
      default:
        return state
    }
  }
};
let reducer = combineReducers(reducers);
export default reducer
