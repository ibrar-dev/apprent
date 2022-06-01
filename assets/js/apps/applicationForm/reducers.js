import {combineReducers} from "redux";
import {extract} from './config';
import moment from 'moment';
import localizaton from '../../components/localization';
import React from "react";

const blankForm = extract('data');

const reducers = {
  property(state = [], {type, property}) {
    if (type === 'SET_PROPERTY') return property;
    return state;
  },
  stage(state = 'occupants', action) {
    switch (action.type) {
      case 'SET_STAGE':
        if (action.stage) return action.stage;
        const stages = Object.keys(blankForm);
        const nextStage = stages.indexOf(state) + (action.increment || 1);
        return stages[nextStage];
      default:
        return state;
    }
  },
  availableUnits(state = [], {type, units}) {
    if (type === 'SET_UNITS') return units;
    return state;
  },
  application(state = {}, {type, section, index, field, value, stage, id, property, models}) {
    let newState;
    switch (type) {
      case 'INITIALIZE_APPLICATION':
        return extract('data', property);
      case 'EDIT_APPLICATION_FIELD':
        newState = {...state};
        if (!newState[section]) return newState;
        if (newState[section].set(index, field, value)) {
          return newState;
        } else {
          newState[section].set(field, value);
          return newState;
        }
      case 'IMPORT_APPLICATION_FIELD':
        newState = {...state};
        newState[section].importObj(value);
        return newState;
      case 'ADD_TO_COLLECTION':
        newState = {...state};
        newState[section].add(value);
        return newState;
      case 'EDIT_COLLECTION':
        newState = {...state};
        newState[section].set(index, field, value);
        return newState;
      case 'FORMAT_COLLECTION':
        newState = {...state};
        newState[section].set(index, field, value.trim());
        return newState;
      case 'DELETE_COLLECTION':
        newState = {...state};
        newState[section].remove(id);
        return newState;
      case 'RESET_COLLECTION':
        newState = {...state};
        newState[section].reset(models);
        return newState;
      default:
        return state;
    }
  },
  language(state = localizaton('en_us'), {type, language}) {
    if (type === 'SET_LANGUAGE') return localizaton(language)
    return state;
  },
  startTime(state = moment().unix(), {type, time}) {
    if (type === 'SET_START_TIME') return time
    return state;
  },
  savedFormId(state = null, {type, id}) {
    if (type === 'SET_SAVED_FORM_ID') return id
    return state;
  }
};

const reducer = combineReducers(reducers);
export default reducer
