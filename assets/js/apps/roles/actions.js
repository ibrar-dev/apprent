import axios from 'axios';
import store from "./store"
import snackbar from "../../components/snackbar";
import setLoading from "../../components/loading";

let actions = {
  fetchRoleTree() {
    axios.get('/api/roles?tree=true').then(r => {
      store.dispatch({
        type: 'SET_ROLE_TREE',
        roleTree: r.data
      })
    })
  },
  fetchRoles() {
    axios.get('/api/roles').then(r => {
      store.dispatch({
        type: 'SET_ROLES',
        roles: r.data.sort((a, b) => a.name > b.name ? 1 : -1)
      })
    })
  },
  createRole(name) {
    setLoading(true);
    const promise = axios.post('api/roles', {role: {name, permissions: {}}});
    promise.then(() => {
      snackbar({
        message: 'Role created',
        args: {type: 'success'}
      })
      actions.fetchRoles();
    })
    promise.catch(e => {
      snackbar({
        message: e.response.data.error,
        args: {type: 'error'}
      });
    });
    promise.finally(() => setLoading(false))
    return promise;
  },
  updateRole(params) {
    setLoading(true);
    const promise = axios.patch('api/roles/' + params.id, {role: params});
    promise.then(() => {
      snackbar({
        message: 'Role updated',
        args: {type: 'success'}
      })
      actions.fetchRoles();
    })
    promise.catch(e => {
      snackbar({
        message: e.response.data.error,
        args: {type: 'error'}
      });
    });
    promise.finally(() => setLoading(false))
  },
  deleteRole(id) {
    setLoading(true);
    const promise = axios.delete('api/roles/' + id);
    promise.then(() => {
      snackbar({
        message: 'Role deleted',
        args: {type: 'success'}
      })
      actions.fetchRoles();
    })
    promise.catch(e => {
      snackbar({
        message: e.response.data.error,
        args: {type: 'error'}
      });
    });
    promise.finally(() => setLoading(false))
  }
}

export default actions;