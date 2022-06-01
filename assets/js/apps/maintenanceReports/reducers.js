import {combineReducers} from "redux";
import setLoading from '../../components/loading';

const reducers = {
  reports(state = [], {type, reports}) {
    if (type === 'SET_REPORTS') {
      return reports.properties.map(r => {
        r.units = [];
        reports.units.forEach(u => {
          if (u.property_id === r.id) r.units.push(u);
        });
        return r;
      });
    }
    return state;
  },
  properties(state = [], {type, properties}) {
    if (type === 'SET_PROPERTIES') return properties;
    return state;
  },
  units(state = [], {type, units}) {
    if (type === 'SET_UNITS') return units;
    return state;
  },
  orders(state = [], {type, orders}) {
    if (type === 'SET_ORDERS') return orders;
    return state;
  },
  dailyReport(state = {}, {type, report}) {
    if (type === 'SET_DAILY_REPORT') return report;
    return state;
  },
  techs(state = [], {type, techs}) {
    if (type === 'SET_TECHS') return techs;
    return state;
  },
  sixMonthStats(state = [], {type, stats}) {
    if (type === 'SET_SIX_MONTH_STATS') return stats;
    return state;
  },
  openHistories(state = [], {type, openHistories}) {
    if (type === 'SET_OPEN_HISTORIES') return openHistories;
    return state;
  },
  completedOrders(state = [], {type, completed}) {
    if (type === 'SET_COMPLETED_ORDERS') return completed;
    return state;
  },
  categoriesOrders(state = [], {type, orders}) {
    if (type === 'SET_CATEGORIES_ORDERS') return orders;
    return state;
  },
  categoriesCompleted(state = [], {type, orders}) {
    if (type === 'SET_CATEGORIES_COMPLETED') return orders;
    return state;
  },
  maintenanceTechs(state = {list: [], detailed: []}, {type, techs}) {
    if (type === 'SET_MIN_TECHS') {
      let newState = state;
      newState.list = techs;
      setLoading(false);
      return newState;
    }
    if (type === 'SET_DETAILED_TECHS') {
      // let newState = state;
      // newState.detailed = techs;
      // setLoading(false);
      // return newState;
      return techs;
    }
    return state;
  },
  katsReport(state = {}, {type, data}) {
    if (type === 'SET_KATS_REPORT') return data;
    return state;
  },
  reportData(state =[], {type, data}) {
    if (type === 'SET_REPORT_DATA') return data;
    return state;
  }
};

const reducer = combineReducers(reducers);
export default reducer;
