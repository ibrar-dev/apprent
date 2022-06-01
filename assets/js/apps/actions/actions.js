import axios from 'axios';
import store from "./store"
import setLoading from '../../components/loading'

const GEOLOCATE_URL = '//extreme-ip-lookup.com/json/';

let actions = {
  fetchActions(params) {
    setLoading(true);
    axios.get('/api/admin_actions', params).then(r => {
      store.dispatch({
        type: 'SET_ACTIONS',
        actions: r.data
      })
    })
    .finally(setLoading(false))
  },
  geolocate({ip}) {
    return axios.get(GEOLOCATE_URL + ip);
  }
};

export default actions
