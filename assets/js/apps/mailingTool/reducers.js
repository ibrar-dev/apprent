import {combineReducers} from "redux";
import setLoading from '../../components/loading';

const reducers = {
  residents(state = [], {type, residents}) {
    if (type === 'SET_RESIDENTS') return residents;
    return state;
  },
  selectedRecipients(state = [], {type, selected}) {
    if (type === 'SET_SELECTED') return selected;
    return state;
  },
  properties(state = [], {type, properties}) {
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  },
  templates(state = [], {type, templates}) {
    if (type === 'SET_TEMPLATES') return templates;
    return state;
  },
  activePresets(state = [], {type, activePresets}) {
    if (type === 'SET_ACTIVE_PRESETS') return activePresets;
    return state
  },
  propertiesTemplate(state = [], {type, propertiesTemplate}) {
    if (type === 'SET_TEMPLATES_PROPERTIES') return propertiesTemplate;
    return state
  }
};


const reducer = combineReducers(reducers);
export default reducer;

