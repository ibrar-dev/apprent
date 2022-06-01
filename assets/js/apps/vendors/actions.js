import axios from 'axios';
import store from './store';

let generators = {
  setProperties: (properties) => {
    const action = {
      type: 'SET_PROPERTIES',
      properties
    };
    store.dispatch(action)
  },
  setVendors: (vendors) => {
    const action = {
      type: 'SET_VENDORS',
      vendors
    };
    store.dispatch(action);

  },
  viewTech: (tech) => {
    const action = {
      type: 'VIEW_VENDOR',
      tech
    };
    store.dispatch(action)
  },
  setVendorCategories: (categories) => {
    const action = {
      type: 'SET_VENDOR_CATEGORIES',
      categories
    };
    store.dispatch(action);
  },
  setVendorOrders: (orders) => {
    const action = {
      type: 'SET_VENDOR_ORDERS',
      orders
    };
    store.dispatch(action);
  }
};
const actions = {
  fetchVendors() {
    const promise = axios.get('/api/vendors');
    promise.then(r => {
      generators.setVendors(r.data);
    });
  },
  fetchProperties() {
    const promise = axios.get('/api/property_meta');
    promise.then(r => generators.setProperties(r.data));
  },
  fetchVendorCategories() {
    const promise = axios.get('/api/vendor_categories');
    promise.then(r => {
      generators.setVendorCategories(r.data);
    });
  },
  refresh() {
    actions.fetchVendors();
    actions.fetchVendorCategories();
    actions.fetchProperties();
  },
  saveVendor(vendor) {
    const promise = axios.post('/api/vendors', {vendor});
    promise.then(actions.refresh);
    return promise;
  },
  deleteVendor(vendor) {
    const promise = axios.patch(`/api/vendors/${vendor.id}`, {delete: {...vendor, active: false}});
    promise.then(actions.refresh);
    return promise;
  },
  updateVendor(vendor) {
    const promise = axios.patch(`/api/vendors/${vendor.id}`, {vendor});
    promise.then(actions.refresh);
    return promise;
  },
  deleteCategory(category) {
    const promise = axios.delete(`/api/vendor_categories/${category.id}`);
    promise.then(actions.refresh);
    return promise;
  },
  showVendor(vendor) {
    if (vendor != null) {
      const promise = axios.get(`/api/vendor_orders/${vendor.id}?order=null`);
      promise.then(r => {
        generators.setVendorOrders({vendor: vendor, orders: r.data});
      });
    } else {
      generators.setVendorOrders(null);
    }
  }
};

export default actions;
