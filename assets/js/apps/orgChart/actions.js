import axios from 'axios';
import store from './store';
import setLoading from '../../components/loading';
import snackbar from '../../components/snackbar';

let actions = {
    updateStatus(id){
      let promise = axios.patch(`/api/admin_permission`, {status_log})
    },
    deleteRule(id){
      let promise = axios.delete(`/api/purchase_order_rules/${id}` )
      return promise.then(actions.fetchRules);
    },
    fetchOrgChart(){
      const promise = axios.get('/api/org_chart');
      return promise;
    },
    save(data){
      setLoading(true)
      const promise = axios.post('/api/org_chart', {data: data})
      promise.then(() => snackbar({message: "Saved.", args: {type: 'success'}}))
      .finally(() => setLoading(false))
      return promise
    },
    // fetchAdmins(){
    //     let promise = axios.get('/api/admins?fetchEmployees=true');
    //     promise.then(r => actions.setAdmin(r.data));
    // },
    fetchVendors(){
        let promise = axios.get('/api/payees');
        promise.then(r => actions.setVendors(r.data));
    },
    deleteAdmin(id){
      const promise = axios.delete('/api/org_chart/' + id)
      return promise;
    },
    fetchProperties(){
        let promise = axios.get('/api/properties');
        promise.then(r => actions.setProperties(r.data));
    },
    setRules(rules){
      store.dispatch({
          type: 'SET_RULES',
          rules: rules
      })
    },
    setItems(items){
      store.dispatch({
        type: 'SET_ITEMS',
        items: items
      })
    },
    setProperties(properties){
        store.dispatch({
            type: 'SET_PROPERTIES',
            properties: properties
        })
    },
    setVendors(vendors){
      store.dispatch({
          type: 'SET_VENDORS',
          vendors: vendors
      })
    },
    setAdmin(admins){
        store.dispatch({
            type: 'SET_ADMINS',
            admins: admins
        })
    },
};

export default actions;
