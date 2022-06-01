import axios from 'axios';
import store from "./store"

let actions = {
  fetchStats() {
    axios.get('/api/user_stats').then(r => {
      store.dispatch({
        type: 'SET_STATS',
        stats: r.data
      })
    })
  },
  fetchProperties() {
    axios.get('/api/property_meta').then(r => {
      store.dispatch({
        type: 'SET_PROPERTIES',
        properties: r.data
      })
    })
  }
};

export default actions
