import axios from 'axios';
import store from "./store"
import setLoading from '../../components/loading';
import snackbar from '../../components/snackbar';

const actions = {
  fetchProperties() {
    setLoading(true);
    const promise = axios.get('/api/properties?min');
    promise.then(r => {
        store.dispatch({
          type: 'SET_PROPERTIES',
          properties: r.data
        });
        const {property} = store.getState();
        if (!property.id) return actions.setProperty(r.data[0] || {});
        r.data.some(p => {
          if (p.id === property.id) {
            actions.setProperty(p);
            return true;
          }
        });
      }
    );
    return promise;
  },
  deletePost(post_id){
    const promise = axios.patch(`/api/posts/${post_id}`, {deletePost:""});
  },
  setProperty(property) {
    store.dispatch({
      type: 'SET_PROPERTY',
      property
    })
    const promise = axios.get(`/api/posts?property_id=${property.id}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_POSTS',
        posts: r.data
      });
      setLoading(false);
    });
    promise.catch(() => {
      setLoading(false);
      snackbar({
        message: 'Unable to fetch Posts :(',
        args: {type: 'warn'}
      })
    })
  },
};

export default actions