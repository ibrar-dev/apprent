import axios from 'axios';
import store from "./store"
import snackbar from "../../components/snackbar";
/* eslint-disable */

let actions = {
  fetchEntities() {
    axios.get('/api/entities').then(r => {
      store.dispatch({
        type: 'SET_ENTITIES',
        entities: r.data
      })
    })
  },

  setAdmins(admins) {
    const action = {
      type: 'SET_ADMINS',
      admins
    };
    store.dispatch(action);
  },

  addAdmin(admin) {
    const action = {
      type: 'ADD_ADMIN',
      admin
    };
    store.dispatch(action)
  },

  removeAdmin(admin) {
    const action = {
      type: 'REMOVE_ADMIN',
      admin
    };
    store.dispatch(action);
  },

  deleteAdmin(admin) {
    const promise = axios.delete(`/api/admins/${admin.id}`);
    promise.then(actions.fetchAdmins);
    return promise;
  },

  fetchAdmins() {
    const promise = axios.get('/api/admins');
    promise.then(r => actions.setAdmins(r.data));
    return promise;
  },

  saveAdmin(admin) {
    const promise = axios.post('/api/admins', {admin});
    promise.then(actions.fetchAdmins);
    return promise;
  },

  updateAdminValues(newVals) {
    const action = {
      type: 'UPDATE_ADMIN',
      newVals
    };
    store.dispatch(action)
  },

  updateAdmin(a) {
    let {id, ...admin} = a;
    let promise;
    if (id === 0) {
      promise = axios.post('/api/admins/', {admin: admin});
      promise.then((r) => {
        actions.removeAdmin(a);
        actions.addAdmin(r.data);
      }).catch(e => e);
    } else {
      promise = axios.patch(`/api/admins/${id}`, {admin: admin});
      promise.then(() => {
        actions.fetchAdmins();
        actions.fetchAdminInfo(id);
      });
    }
    return promise;
  },

  updateProfile(admin_profile, id) {
    const promise = id ? axios.patch(`/api/admin_profile/${id}`, admin_profile) : axios.post(`/api/admin_profile`, admin_profile);
    promise.then(() => {
      this.fetchAdmins();
      snackbar({message: "Profile successfully updated", args: {type: "success"}});
    });
    promise.catch(() => {
      snackbar({message: "Error updating profile", args: {type: "error"}});
    });
    return promise;
  },

  addAddress(address, admin_id) {
    const promise = axios.post('/api/mail_addresses', {mail_address: {admin_id, address}});
    promise.then(r => actions.getAddresses());
    return promise;
  },

  getAddresses() {
    const promise = axios.get('/api/mail_addresses');
    promise.then(r => actions.setMailAddresses(r.data));
    return promise;
  },

  setMailAddresses(addresses) {
    const action = {
      type: 'SET_ADDRESSES',
      addresses
    };
    store.dispatch(action)
  },

  assignAdmin(adminId, assigned, entityId) {
    const promise = axios.patch('/api/entities/' + entityId, {admin_id: adminId, attach: assigned});
    promise.then(r => {
        actions.fetchAdminInfo(adminId)
      }
    );
    return promise;
  },

  setAdmin(admin) {
    store.dispatch({
      type: 'SET_ADMIN',
      admin: admin
    })
  },

  fetchAdminInfo(adminId) {
    const promise = axios.get(`/api/admins/${adminId}`);
    promise.then((r) => {
      this.fetchAdminAction(adminId);
      this.getInsightSubscriptions(adminId);
      store.dispatch({
        type: 'SET_ACTIVE_ADMIN',
        activeAdmin: r.data
      })
    })
    return promise;
  },

  fetchAdminAction(adminId) {
    axios.get(`/api/admin_actions/${adminId}`).then(r => {
      store.dispatch({
        type: 'SET_ACTIONS',
        actions: r.data
      })
    })
  },

  getInsightSubscriptions(adminId) {
    axios.get(`/api/insight_subscriptions?admin_id=${adminId}`).then(r => {
      store.dispatch({
        type: 'SET_INSIGHT_SUBSCRIPTIONS',
        actions: r.data.list
      })
    })
  },

  addInsightSubscription(property_id, adminId, type) {
    const body = {
      admin_id: adminId,
      property_id,
      type,
    }

    axios.post(`/api/insight_subscriptions/`, body).then(r => {
      store.dispatch({
        type: 'SET_INSIGHT_SUBSCRIPTIONS',
        actions: r.data.list
      })
    })
  },

  removeInsightSubscription(subscriptionId, adminId) {
    axios.delete(`/api/insight_subscriptions/${subscriptionId}`)
    this.getInsightSubscriptions(adminId);
  }
};

export default actions
