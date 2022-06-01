import {combineReducers} from "redux"
const reducers = {
  properties: (state = [], action)=>{
    switch(action.type){
      case 'SET_PROPERTIES':
        return action.properties;
      default:
        return state
    }
  },
  property(state = {}, {type, property}) {
    if (type === 'SET_PROPERTY') return property;
    return state;
  },
  posts(state = [], {type, posts}) {
    if (type === 'SET_POSTS') {
      posts.forEach(p => {
        p.likesCount = p.likes.length;
        p.reportsCount = p.reports.length;
      });
      return posts;
    }
    return state;
  }
};

export default combineReducers(reducers);