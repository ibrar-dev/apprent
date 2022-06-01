import axios from "axios";
import store from "./store";
import snackbar from "../../components/snackbar";
import setLoading from "../../components/loading";
import {getCookie} from "../../utils/cookies";

const windowProperties = window.properties;

const actions = {
  initializeChannel() {
    actions.channel = new Channel();
    actions.channel.register("coordinates", actions.setCoordinates);
    actions.channel.register("presence_diff", actions.setPresence);
  },
  setPresence({leaves, joins}) {
    const {techs} = store.getState();
    const updated = techs.map((t) => {
      if (leaves[t.id]) return {...t, presence: false};
      if (joins[t.id]) return {...t, presence: true};
      return t;
    });
    store.dispatch({
      type: "SET_TECHS",
      techs: updated,
    });
  },
  setCoordinates(content) {
    const {tech_id, ...coords} = content.msg;
    const {techs} = store.getState();
    const updated = techs.map((t) => t.id === tech_id ? {...t, ...coords} : t);
    store.dispatch({
      type: "SET_TECHS",
      techs: updated,
    });
  },
  setSkeleton(value) {
    store.dispatch({
      type: "SET_SKELETON",
      value,
    });
  },
  fetchOrders(properties, dates) {
    const cookie = getCookie("multiPropertySelector");
    if (!properties && !cookie && !windowProperties.length) return;
    actions.setSkeleton(true);
    let url = "";
    if (dates) {
      url = `/api/orders?new&dates=${dates}&properties=${properties || cookie || windowProperties[0].id}`;
    } else {
      url = `/api/orders?new&dates&properties=${properties || cookie || windowProperties[0].id}`;
    }
    const promise = axios.get(url);
    promise.then((r) => {
      store.dispatch({
        type: "SET_NEW_ORDERS",
        orders: r.data,
      });
      actions.setSkeleton(false);
    });
    promise.catch(() => {
      snackbar({
        message: "Unable to Fetch Orders",
        args: {type: "error"},
      });
      actions.setSkeleton(false);
    });
  },
  setOrderData(data) {
    store.dispatch({
      type: "SET_ORDER_DATA",
      data,
    });
  },
  assignWorkOrder(tech_id, order_id) {
    const promise = axios.post("/api/assignments", {assignment: {tech_id, order_id}});
    promise.then(() => {
      actions.openWorkOrder(order_id, "workOrder");
      snackbar({message: "Work Order assigned", args: {type: "success"}});
    }).catch(() => {
      snackbar({
        message: "Work Order has not been assigned. An email has been sent to the IT admins to address the issue",
        args: {type: "warn"},
      });
    });
    return promise;
  },
  assignWorkOrders(order_ids, tech_id) {
    const body = {order_ids, tech_id};
    const promise = axios.post("/api/assignments", body);
    promise.then(() => {
      actions.fetchOrders();
      snackbar({message: "Work Orders successfully assigned", args: {type: "success"}});
    }).catch(() => {
      snackbar({
        message: "Some of the selected Work Orders have not been assigned. An email has been sent to the IT admins to address the issue",
        args: {type: "warn"},
      });
    });
    return promise;
  },
  outsourceOrder(vendor_order) {
    const promise = axios.post("/api/vendor_orders", vendor_order);
    promise.then(() => {
      snackbar({message: "Order has been successfully outsourced.", args: {type: "success"}});
    }).catch(() => {
      snackbar({
        message: "Order has NOT been outsourced. Please make sure all the information is correct. If you are still having problems please contact an IT admin",
        args: {type: "error"},
      });
    });
    return promise;
  },
  outsourceOrders(orders) {
    const promise = axios.post("/api/vendor_orders", {orders});
    promise.then(() => {
      actions.fetchOrders();
      snackbar({message: "Order has been successfully outsourced.", args: {type: "success"}});
    }).catch((e) => {
      snackbar({
        message: e,
        args: {type: "error"},
      });
    });
    return promise;
  },
  callbackOrder(assignment, note) {
    const promise = axios.patch(`/api/assignments/${assignment.id}?callback=true`, {note});
    promise.then(() => {
      snackbar({message: "Work Order successfully called back.", args: {type: "success"}});
    }).catch((e) => {
      snackbar({
        message: e,
        args: {type: "error"},
      });
    });
    return promise;
  },
  deleteAssignment(id, order_id) {
    const promise = axios.delete(`/api/assignments/${id}?trueDelete=`);
    promise.then(() => {
      actions.openWorkOrder(order_id, "workOrder");
      snackbar({
        message: "Assignment deleted",
        args: {type: "success"},
      });
    });
    promise.catch(() => {
      snackbar({
        message: "Assignment has NOT been deleted",
        args: {type: "error"},
      });
    });
  },
  editRating(id, rating) {
    return axios.patch(`/api/assignments/${id}`, {assignment_id: id, rating});
  },
  fetchCategories() {
    const promise = axios.get("/api/categories");
    promise.then((r) => {
      store.dispatch({
        type: "SET_CATEGORIES",
        categories: r.data,
      });
    });
  },
  fetchSubCategories() {
    const promise = axios.get("/api/categories?assign");
    promise.then((r) => {
      store.dispatch({
        type: "SET_SUBCATEGORIES",
        subcategories: r.data,
      });
    });
  },
  fetchTechs() {
    const promise = axios.get("/api/techs");
    promise.then((r) => {
      store.dispatch({
        type: "SET_TECHS",
        techs: r.data,
      });
    }).catch(() => {
      store.dispatch({
        type: "SET_TECHS",
        techs: null,
      });
    });
  },
  saveNote(order_id, notes, type) {
    const promise = type === "vendor" ? axios.post("/api/vendor_notes/", notes) : axios.post("/api/notes/", notes);
    promise.then(() => {
      snackbar({message: "Note has been added to the work order", args: {type: "success"}});
    }).catch(() => {
      snackbar({
        message: "Note has NOT been added to the work order. Please make sure all the information is correct. If you are still having problems please contact an IT admin",
        args: {type: "error"},
      });
    });
    return promise;
  },
  deleteNote(id, order_id) {
    const promise = axios.delete(`/api/notes/${id}`);
    promise.then(() => {
      actions.openWorkOrder(order_id, "workOrder");
      snackbar({message: "Note has been deleted", args: {type: "success"}});
    });
  },
  deleteWorkOrder(id, reason) {
    const promise = axios.patch(`/api/orders/${id}`, {reason});
    promise.then(() => {
      actions.openWorkOrder(id, "workOrder");
      snackbar({message: `Work Order Canceled - ${reason}`, args: {type: "warn"}});
    });
    return promise;
  },
  searchForMaterials(term) {
    setLoading(true);
    const promise = axios.get(`/api/materials?search=${term}`);
    promise.then((r) => {
      store.dispatch({
        type: "SET_SEARCH_RESULTS",
        results: r.data,
      });
      setLoading(false);
    });
  },
  attachMaterial(toolbox, order_id, search) {
    const promise = axios.post("/api/toolbox_items?admin_add", {toolbox});
    promise.then(() => {
      snackbar({
        message: "Material Added To Order",
        args: {type: "success"},
      });
      actions.searchForMaterials(search);
      actions.openWorkOrder(order_id, "workOrder");
    }).catch(() => {
      snackbar({
        message: "Something went wrong.",
        args: {type: "error"},
      });
    });
  },
  fetchVendorCategories() {
    const promise = axios.get("/api/vendor_categories");
    promise.then((r) => {
      store.dispatch({
        type: "SET_VENDOR_CATEGORIES",
        categories: r.data,
      });
    });
  },
  fetchVendors() {
    const promise = axios.get("/api/vendors");
    promise.then((r) => {
      store.dispatch({
        type: "SET_VENDORS",
        vendors: r.data,
      });
    });
  },
  updateVendorOrder(vendorOrder) {
    const promise = axios.patch(`/api/vendor_orders/${vendorOrder.id}`, {vendorOrder});
    promise.then(() => {
      snackbar({message: "Order has been successfully updated.", args: {type: "success"}});
    }).catch(() => {
      snackbar({
        message: "Order has NOT been updated. Please make sure all the information is correct. If you are still having problems please contact an IT admin",
        args: {type: "error"},
      });
    });
    return promise;
  },
  deleteVendorOrder(id) {
    const promise = axios.delete(`/api/vendor_orders/${id}`);
    promise.then(() => {
      snackbar({
        message: "Order successfully deleted",
        args: {type: "success"},
      });
    }).catch(() => {
      snackbar({
        message: "Order NOT deleted",
        args: {type: "error"},
      });
    });
    return promise;
  },
  updateWorkOrder(id, workOrder) {
    if (!workOrder.append) {
      workOrder = {workOrder};
    }
    const promise = axios.patch(`/api/orders/${id}`, workOrder);
    promise.then(() => {
      actions.openWorkOrder(id, "workOrder");
      snackbar({message: "Work Order successfully updated", args: {type: "success"}});
    }).catch(() => {
      snackbar({
        message: "Work Order has NOT been updated. Please make sure all the information is correct. If you are still having problems please contact an IT admin",
        args: {type: "error"},
      });
    });
    return promise;
  },
  bugResident(assignment_id, order_id) {
    const promise = axios.patch(`/api/assignments/${assignment_id}?bug=`);
    promise.then(() => {
      actions.openWorkOrder(order_id, "workOrder");
      snackbar({
        message: "Resident successfully bugged",
        args: {type: "success"},
      });
    });
    promise.catch(() => {
      actions.openWorkOrder(order_id, "workOrder");
      snackbar({
        message: "Resident has been bugged, lucky resident, but the server for some reason thinks they have not, but they have been.",
        args: {type: "error"},
      });
    });
  },
  notifyTenantOfArrival(id, time) {
    return axios.patch(`/api/assignments/${id}`, {assignment_id: id, time});
  },
  setPending(status) {
    setLoading(status);
  },
  openWorkOrder(orderId, type) {
    actions.setPending(true);
    if (type === "workOrder") {
      axios.get(`/api/orders/${orderId}`).then((r) => {
        store.dispatch({
          type: "OPEN_WORK_ORDER",
          order: r.data,
        });
        actions.setPending(false);
      });
    } else {
      axios.get(`/api/vendor_orders/${orderId}?order=order`).then((r) => {
        store.dispatch({
          type: "OPEN_WORK_ORDER",
          order: r.data,
        });
        actions.setPending(false);
      });
    }
  },
  revokeAssignment(assignmentId) {
    const promise = axios.delete(`/api/assignments/${assignmentId}`);
    promise.then(() => {
      actions.fetchOrders();
      snackbar({
        message: "Assignment has been revoked and the order is now in the Unassigned category.",
        args: {type: "success"},
      });
    }).catch(() => {
      snackbar({
        message: "Assignments has NOT been revoked. Please contact an IT admin regarding this order",
        args: {type: "error"},
      });
    });
    return promise;
  },
  revokeAssignments(assignment_ids) {
    const body = {data: {assignment_ids}};
    axios.delete("/api/assignments/0", body).then(() => {
      snackbar({
        message: "Assignments have been revoked and the orders are now in the Unassigned category.",
        args: {type: "success"},
      });
      actions.fetchOrders();
    }).catch(() => {
      snackbar({
        message: "Assignments have NOT been revoked. Please contact an IT admin regarding this order",
        args: {type: "error"},
      });
    });
  },
  createPart(part) {
    const promise = axios.post("/api/maintenance_parts", part);
    promise.then(() => {
      actions.openWorkOrder(part.order_id, "workOrder");
      snackbar({
        message: "Part successfully added. Please note that this order cannot be assigned until all parts have been delivered",
        args: {type: "success"},
      });
    }).catch(() => {
      snackbar({
        message: "Part has NOT been added to the work order. Please make sure all the information is correct. If you are still having problems please contact an IT admin",
        args: {type: "error"},
      });
    });
    return promise;
  },
  updatePart(id, orderId, part) {
    const promise = axios.patch(`/api/maintenance_parts/${id}`, part);
    promise.then(() => {
      actions.openWorkOrder(orderId, "workOrder");
      snackbar({
        message: "Part successfully updated. Please note that this order cannot be assigned until all parts have been delivered",
        args: {type: "success"},
      });
    }).catch(() => {
      snackbar({
        message: "Part has NOT been updated. Please make sure all the information is correct. If you are still having problems please contact an IT admin",
        args: {type: "error"},
      });
    });
    return promise;
  },
  fetchEveryone() {
    const promise = axios.get("/api/org_chart?everyone");
    promise.then((r) => {
      store.dispatch({
        type: "SET_ADMINS",
        admins: r.data,
      });
    });
  },
  fetchOrderNotes(orderId, orderType, onSuccess) {
    setLoading(true);
    axios.get(`/api/notes?fetch_notes=true&order_id=${orderId}&order_type=${orderType}`)
      .then((r) => {
        onSuccess(r);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  },
};

export default actions;
