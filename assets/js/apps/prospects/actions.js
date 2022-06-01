import axios from 'axios';
import store from "./store"

const actions = {
  fetchProspects() {
    axios.get('/api/prospects').then(r => {
      store.dispatch({
        type: 'SET_PROSPECTS',
        prospects: r.data
      })
    });
  },
  fetchAgents() {
    axios.get('/api/agents').then(r => {
      store.dispatch({
        type: 'SET_AGENTS',
        agents: r.data
      })
    });
  },
  fetchTrafficSources() {
    axios.get('/api/traffic_sources').then(r => {
      store.dispatch({
        type: 'SET_TRAFFIC_SOURCES',
        trafficSources: r.data
      })
    });
  },
  fetchProperties() {
    const promise = axios.get('/api/property_meta');
    promise.then(r => {
      store.dispatch({
        type: 'SET_PROPERTIES',
        properties: r.data
      })
    });
    return promise;
  },
  fetchShowings() {
    axios.get('/api/showings').then(r => {
      store.dispatch({
        type: 'SET_SHOWINGS',
        showings: r.data
      })
    });
  },
  fetchOpenings() {
    axios.get('/api/openings').then(r => {
      store.dispatch({
        type: 'SET_OPENINGS',
        openings: r.data
      })
    });
  },
  setProperty(property) {
    store.dispatch({
      type: 'SET_PROPERTY',
      property
    })
  },
  refresh() {
    actions.fetchShowings();
    actions.fetchProspects()
  },
  createProspect(p) {
    const {property: {id}} = store.getState();
    const promise = axios.post('/api/prospects', {prospect: {...p, property_id: id}});
    promise.then(actions.fetchProspects);
    return promise;
  },
  updateProspect(p) {
    const promise = axios.patch('/api/prospects/' + p.id, {prospect: p});
    promise.then(actions.fetchProspects);
    return promise;
  },
  createShowing(showing) {
    const {property: {id}} = store.getState();
    const promise = axios.post('/api/showings', {showing: {...showing, property_id: id}});
    promise.then(actions.refresh);
    return promise;
  },
  deleteShowing(showing) {
    const promise = axios.delete('/api/showings/' + showing.id);
    promise.then(actions.refresh);
    return promise;
  },
  deleteProspect(prospect) {
    const promise = axios.delete('/api/prospects/' + prospect.id);
    promise.then(actions.refresh);
    return promise;
  },
  saveMemo(memo) {
    const promise = axios.post('/api/prospects', {memo});
    promise.then(actions.refresh);
    return promise;
  },
};

export default actions;
