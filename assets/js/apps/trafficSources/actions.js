import axios from 'axios';
import store from "./store"

const actions = {
  fetchTrafficSources() {
    axios.get('/api/traffic_sources').then(r => {
      store.dispatch({
        type: 'SET_TRAFFIC_SOURCES',
        trafficSources: r.data
      })
    });
  },
  createTrafficSource(params) {
    const promise = axios.post('/api/traffic_sources', {traffic_source: params});
    promise.then(actions.fetchTrafficSources);
    return promise;
  },
  updateTrafficSource(p) {
    const promise = axios.patch('/api/traffic_sources/' + p.id, {traffic_source: p});
    promise.then(actions.fetchTrafficSources);
    return promise;
  },
  deleteTrafficSource(p) {
    const promise = axios.delete('/api/traffic_sources/' + p.id);
    promise.then(actions.fetchTrafficSources);
    return promise;
  }
};

export default actions;
