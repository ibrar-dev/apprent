import {combineReducers} from "redux"

const reducers = {
  cards(state = [], {type, cards}) {
    if (type === "SET_CARDS") return cards;
    return state;
  },
  hiddenCards(state = [], {type, hiddenCards}) {
    if (type === "SET_HIDDEN_CARDS") return hiddenCards;
    return state;
  },
  domainEvent(state = {}, {type, domainEvent}) {
    if (type === "SET_LAST_DOMAIN_EVENT") return domainEvent;
    return state;
  },
  items(state = [], {type, items}) {
    if (type === "SET_ITEMS") return items;
    return state;
  },
  techs(state = [], {type, techs}) {
    if (type === "SET_TECHS") return techs;
    return state;
  },
  vendors(state = [], {type, vendors}) {
    if (type === "SET_VENDORS") return vendors;
    return state;
  },
  units(state = [], {type, units}) {
    if (type === "SET_UNITS") return units;
    return state;
  },
  unitInfo(state = {}, {type, unit}) {
    if (type === "SET_UNIT_INFO") return unit;
    return state;
  },
  mode(state = {}, {type, mode}) {
    if (type === "SET_MODE") return mode;
    return state;
  },
  properties(state = [], {type, properties}) {
    if (type === "SET_PROPERTIES") return properties;
    return state;
  },
  selectedProperties(state = [], {type, properties}) {
    if (type === "SELECT_PROPERTIES") return properties;
    return state;
  },
  vendor_categories(state = [], {type, categories}) {
    if (type === "SET_VENDOR_CATEGORIES") return categories;
    return state;
  }
};
export default combineReducers(reducers);
