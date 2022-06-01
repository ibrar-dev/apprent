import axios from 'axios';
import store from './store';
import setLoading from '../../components/loading';
import snackbar from '../../components/snackbar';
import React from "react";

const actions = {
  setPropertiesSelected(propertiesSelected) {
    store.dispatch({
      type: "SET_PROPERTIES_SELECTED",
      propertiesSelected,
    });
  },
  fetchProperties() {
    setLoading(true);
    const promise = axios.get('/api/property_meta');
    promise.then(r => {
      store.dispatch({
        type: 'SET_PROPERTIES',
        properties: r.data
      });
    })
    promise.catch(() => {
      snackbar({
        message:"Error fetching properties",
        args: {type: 'error'},
      });
    })
  },
  fetchApprovals() {
    const {propertiesSelected} = store.getState();
    if (!propertiesSelected || propertiesSelected.length === 0) return null;
    setLoading(true)
    var arrStr = propertiesSelected.map((p) => `property_ids[]=${p}`).join("&")
    const promise = axios.get(`/api/approvals?${arrStr}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_APPROVALS',
        approvals: r.data
      })
    });
    promise.catch(() => {
      snackbar({
        message:"Error fetching approvals",
        args: {type: 'error'}
      });
    });
    setLoading(false);
  },
  fetchVendors() {
    setLoading(true)
    const promise = axios.get(`/api/payees?meta=true`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_PAYEES',
        payees: r.data
      })
    });
    promise.catch(() => {
      snackbar({
        message:"Error fetching vendors",
        args: {type: 'error'}
      });
    });
    setLoading(false);
  },
  createVendor(params) {
    const promise = axios.post('/api/payees', {payee: params});
    promise.then(() => {
      snackbar({
        message: "Successfully saved vendor.\nPlease select them from the list.",
        args: {type: 'success'}
      })
      actions.fetchVendors()
    }).catch( () => {
      snackbar({
        message: "Error saving vendor.",
        args: {type: 'error'}
      })
    });
    return promise;
  },
  fetchCategories(propertyId) {
    const promise = axios.get(`/api/approvals?categories=${propertyId}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_ACCOUNTING_CATEGORIES',
        categories: r.data
      })
    })
  },
  fetchAdmins() {
    setLoading(true)
    const promise = axios.get(`/api/approvals?approvers=true`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_APPROVERS',
        approvers: r.data
      })
    });
    promise.catch(() => {
      snackbar({
        message:"Error fetching supervisors",
        args: {type: 'error'}
      });
    });
    setLoading(false);
  },
  fetchEveryone() {
    const promise = axios.get('/api/org_chart?everyone');
    promise.then(r => {
      store.dispatch({
        type: 'SET_EVERYONE',
        everyone: r.data
      })
    });
  },
  fetchApprovalNumber(payee_id, property_id) {
    return axios.get(`/api/approvals?nextNum=true&payee_id=${payee_id}&property_id=${property_id}`);
  },
  updateApproval(id, approval){
    const promise = axios.patch(`/api/approvals/${id}`, {approval: approval})
    promise.then(r => actions.fetchApproval(id))
    promise.catch(e => {
      snackbar({
        message: "There as an error saving the approval.",
        args: {type: 'error'}
      })
    })
    return promise;
  },
  deleteAttachment(id, approvalId){
    const promise = axios.delete(`/api/approvals/${id}?deleteAttachment`);
    promise.then(() => actions.fetchApproval(approvalId))
  },
  saveApproval(approval, history) {
    const {approver} = approval;
    const {approvers} = store.getState();
    const promise = axios.post(`/api/approvals`, {approval});
    promise.then(r => {
      let message = "";
      if (approver && approver.length > 0) {
        approver.forEach((a, i) => {
          let message2 = "";
          if (message.length) message2 = " and ";
          message = message.concat(message2, approvers.filter(ap => ap.id === a)[0].name);
        })
      }
      snackbar({
        message: (<div>
          <p>Approval Saved</p>
          <p>{message.length > 0 ? message : 'Your supervisor has been'} Notified</p>
        </div>),
        args: {type: 'success'}
      });
      history.push("/approvals");
    })
    promise.catch(e => {
      snackbar({
        message: e.response.data,
        args: {type: 'error'}
      });
    })
    return promise;
  },
  storeAttachment(attachments){
    store.dispatch({
      type: 'SET_ATTACHMENT',
      attachments: attachments
    })
  },
  fetchApproval(id) {
    setLoading(true)
    const promise = axios.get(`/api/approvals/${id}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_APPROVAL',
        approval: r.data
      });
      actions.fetchCategories(r.data.property_id);
      actions.storeAttachment(r.data.attachments)
    })
    promise.catch(e => {
      snackbar({
        message: "Error getting approval info",
        args: {type: 'error'}
      });
    })
    setLoading(false);
    return promise;
  },
  createApprovalLog(id, approval_log) {
    setLoading(true);
    const promise = axios.patch(`/api/approvals_logs/${id}`, {approval_log});
    promise.then(r => {
      snackbar({
        message: 'Request Updated',
        args: {type: 'success'}
      });
      actions.fetchApproval(id);
    })
    promise.catch(e => {
      snackbar({
        message: e.response.data,
        args: {type: 'error'}
      });
    })
    setLoading(false);
    return promise;
  },
  saveApprovalNote(approval_note) {
    const promise = axios.post(`/api/approvals`, {approval_note});
    promise.then(r => {
      snackbar({
        message: 'Note Saved',
        args: {type: 'success'}
      });
      actions.fetchApproval(approval_note.approval_id);
    })
    promise.catch(e => {
      snackbar({
        message: e.response.data,
        args: {type: 'error'}
      });
    })
    setLoading(false);
  },
  deleteApprovalLog(approval_id, log_id){
    setLoading(true);
    const promise = axios.delete(`/api/approvals_logs/${log_id}`);
    promise.then(() => {
      snackbar({
        message: "Log deleted.",
        args: {type: 'success'}
      });
      actions.fetchApproval(approval_id);
    });
    promise.catch((e) => {
      snackbar({
        message: e.response.data.error || "Error deleting log.",
        args: {type: 'error'}
      })
    });
    setLoading(false);
  },
  fetchAdminData(property) {
    setLoading(true);
    const promise = axios.get('/api/approvals',{params:{adminData:"", property_id: property.id}});
    promise.then(r => {
      store.dispatch({
        type: 'SET_ADMIN_DATA',
        adminData: r.data
      })
    });
    promise.catch(e => {
      snackbar({
        message: e.response.data.error || "Error fetching dashboard data.",
        args: {type: 'error'}
      })
    });
    setLoading(false)
  },
  fetchOtherAdminData(admin_id){
    var property = {...store.getState().property};
    setLoading(true);
    const promise = axios.get(`/api/approvals`,{params: {approval_id: admin_id, adminData:true, property_id: property.id}});
    promise.then(r => {
      store.dispatch({
        type: 'SET_ADMIN_DATA',
        adminData: r.data
      })
      store.dispatch({
        type: 'SET_ADMIN',
        admin: admin_id
      })
    });
    promise.catch(e => {
      snackbar({
        message: e.response.data.error || "Error fetching dashboard data.",
        args: {type: 'error'}
      })
    });
    setLoading(false)
  },
  getMoneySpent(params) {
    setLoading(true);
    const promise = axios.get(`/api/approval_costs/${params.category_id}?property_id=${params.property_id}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_MONEY_SPENT',
        spent: r.data
      });
      setLoading(false);
    });
    promise.catch(e => {
      snackbar({
        message: e.response.data.error || "Error fetching dashboard data.",
        args: {type: 'error'}
      });
      setLoading(false);
    });
  },
  fetchApprovalChartData(adm,prop) {
    const property = prop ? prop : {...store.getState().property}
    const admin_id = adm ? adm : parseInt(window.user.id)
    const promise = axios.get(`/api/approval_costs`, {params: {chart_data: "", property_id: property.id, admin_id: admin_id}});
    promise.then((r) => {
      store.dispatch({
        type: 'SET_CHART_DATA',
        data: r.data
      })
    });
    return promise;
  }
};

export default actions;
