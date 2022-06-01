import axios from 'axios';
import store from "./store"
import setLoading from '../../components/loading';

const actions = {
  fetchWorkOrderCategories() {
    setLoading(true);
    axios.get('/api/work_order_categories').then(r => {
      store.dispatch({
        type: 'SET_CATEGORIES',
        categories: r.data
      });
      setLoading(false);
    });
  },
  transfer(fromId, targetId) {
    setLoading(true);
    const promise = axios.patch(`/api/work_order_categories/${fromId}`, {transfer: targetId});
    promise.then(actions.fetchWorkOrderCategories);
    return promise;
  },
  deleteCategory(id) {
    const promise = axios.delete(`/api/work_order_categories/${id}`);
    promise.then(actions.fetchWorkOrderCategories);
    return promise;
  },
  createChild(parentId, name) {
    const promise = axios.post(`/api/work_order_categories`, {category: {path: [parentId], name}});
    promise.then(actions.fetchWorkOrderCategories);
    return promise;
  },
  updateCategory(id, name) {
    const promise = axios.patch(`/api/work_order_categories/${id}`, {category: {name}});
    promise.then(actions.fetchWorkOrderCategories);
    return promise;
  },
  toggleVisibility(id, category) {
    const promise = axios.patch(`/api/work_order_categories/${id}`, {category});
    promise.then(actions.fetchWorkOrderCategories);
    return promise;
  }
};

export default actions;