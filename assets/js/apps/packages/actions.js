import axios from 'axios';
import store from './store';

let generators = {

  setFilteredPackages: (packages,selectedProperties) => {
    const action = {
      type: 'SET_PACKAGES',
      packages
    };
        store.dispatch(action);

  },
  setTenants: (tenants) => {
    const action = {
      type: 'SET_TENANTS',
      tenants
    };
    store.dispatch(action)
  }
};
const actions = {
  fetchFilteredPackages(selectedProperties) {
    const promise = axios.get(`/api/packages?property_ids=${selectedProperties}`);
    promise.then(r => {
      store.dispatch({
        type: "SET_PACKAGES",
        packages: r.data
      })
    })
    // promise.then(r => {
    //   generators.setFilteredPackages(r.data,selectedProperties);
    // });
  },
  fetchTenants() {
    const promise = axios.get('/api/tenants?min=true');
    promise.then(r => {
      generators.setTenants(r.data);
    });
  },
  savePackage(pack) {
    const promise = axios.post('/api/packages', {pack});
    promise.then(actions.fetchPackages);
    return promise;
  },
  deletePackage(pack) {
    const promise = axios.delete(`/api/packages/${pack.id}`);
    promise.then(actions.fetchPackages);
    return promise;
  },
  updatePackage (pack) {
    const promise = axios.patch(`/api/packages/${pack.id}`, {pack});
    promise.then(actions.fetchPackages);
    return promise;
  },
  updatePackages (packageIds) {
    packageIds.forEach((x) => {
      actions.updatePackage(x);
    })
  },
  updateTenants (string) {
    const promise = axios.get(`/api/tenants?name=${string}`);
    promise.then(r => {
      generators.setTenants(r.data.tenants);
    })
  }
};

export default actions;
