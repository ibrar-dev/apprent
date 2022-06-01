import store from './store';
import axios from 'axios';

const actions = {
  fetchOpenings() {
    axios.get('/api/showings/' + window.PROPERTY_ID).then(r => {
      store.dispatch({
        type: 'SET_OPENINGS',
        openings: r.data.openings
      });
      store.dispatch({
        type: 'SET_SHOWINGS',
        showings: r.data.showings
      });
      store.dispatch({
        type: 'SET_CLOSURES',
        closures: r.data.closures
      })
    });
  },
  createShowing(params) {
    const referral = new URLSearchParams(window.location.search).get('referral')
    const new_params = params;
    if (referral) {
      new_params.referral = referral
    }
    return axios.post('/api/showings', {showing: {...new_params, property_id: window.PROPERTY_ID}});
  }
};

export default actions;