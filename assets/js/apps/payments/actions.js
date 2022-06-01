import axios from "axios";
import store from "./store";
import setLoading from "../../components/loading";
import snackbar from "../../components/snackbar";
import { getCookie } from "../../utils/cookies";

const actions = {
  fetchBatches(onSuccess) {
    const {dateFilters} = store.getState();
    const {startDate, endDate} = dateFilters;
    const cookie = getCookie("multiPropertySelector");
    const cookieProperties = cookie ? cookie.split(",") : [];
    setLoading(true);
    const fmt = "YYYY-MM-DD";
    let query = `start=${startDate.format(fmt)}&end=${endDate.format(fmt)}`;
    cookieProperties.forEach((propertyId) => query += `&property_ids[]=${propertyId}`);
    if (!(cookieProperties && cookieProperties.length)) return setLoading(false) && null;
    return axios.get(`/api/batches?${query}`).then(({data}) => {
      store.dispatch({type: "SET_BATCHES", batches: data});
      setLoading(false);
      onSuccess(data);
    });
  },
  setDateFilters([startDate, endDate], onFetchSuccess) {
    store.dispatch({
      type: "SET_DATE_FILTERS",
      value: {startDate, endDate},
    });

    this.fetchBatches(onFetchSuccess);
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
  fetchVendorCategories() {
    const promise = axios.get("/api/vendor_categories");
    promise.then((r) => {
      store.dispatch({
        type: "SET_VENDOR_CATEGORIES",
        vendor_categories: r.data,
      });
    });
  },
  refresh() {
    actions.fetchVendors();
    actions.fetchVendorCategories();
    actions.fetchProperties();
  },
  saveVendor(vendor) {
    const promise = axios.post("/api/vendors", {vendor});
    promise.then(actions.refresh);
    return promise;
  },

  fetchProperties() {
    axios.get("/api/property_meta").then((r) => {
      store.dispatch({
        type: "SET_PROPERTIES",
        properties: r.data,
      });
    });
  },
  fetchBankAccounts(propertyId) {
    return axios.get(`/api/bank_accounts?property_id=${propertyId}`);
  },
  fetchAccounts() {
    const promise = axios.get("/api/accounts");
    promise.then((r) => {
      store.dispatch({
        type: "SET_ACCOUNTS",
        accounts: r.data,
      });
    });
    return promise;
  },
  deletePayment(id, onSuccess) {
    const promise = axios.delete(`/api/payments/${id}`);
    promise.then(() => {
      actions.fetchBatches(onSuccess);
      snackbar({
        message: "Payment Deleted",
        args: {type: "success"},
      });
    });
    promise.catch(() => {
      actions.fetchBatches();
      snackbar({
        message: "Payment NOT deleted",
        args: {type: "error"},
      });
    });
  },
  fetchTenants(propertyId) {
    setLoading(true);
    const promise = axios.get(`/api/tenants?property_id=${propertyId}`);
    promise.then(() => setLoading(false));
    return promise;
  },
  fetchApplicants(propertyId) {
    setLoading(true);
    const promise = axios.get(`/api/applications?payment_applicants=true&property_id=${propertyId}`);
    promise.then(() => setLoading(false));
    return promise;
  },
  createDeposit(params, onSuccess) {
    const promises = params.items.map((p) => p.image.upload());
    const {inserted_at, post_month} = params;
    return Promise.all(promises).then(() => {
      setLoading(true);
      params.items.forEach((i) => {
        i.inserted_at = inserted_at;
        i.post_month = post_month;
        i.image = {uuid: i.image.uuid};
      });
      const {property_id, items, bank_account_id} = params;
      const batch = {property_id, items, bank_account_id};
      const promise = axios.post("/api/batches", {batch});
      promise.then(() => {
        snackbar({
          message: "Deposit created",
          args: {type: "success"},
        });
        onSuccess();
      }).catch((r) => {
        snackbar({
          message: r.response.data.error,
          args: {type: "error"},
        });
        setLoading(false);
      });
    });
  },
  deleteDeposit(id, onSuccess) {
    setLoading(true);
    return axios.delete(`/api/batches/${id}`)
      .then(() => actions.fetchBatches(onSuccess))
      .catch(() => setLoading(false));
  },

  getPaymentImageURL(id) {
    return axios.get(`/api/payments/${id}?type`).then((r) => {
      store.dispatch({
        type: "SET_PAYMENT_IMAGE",
        paymentImage: r.data,
      });
    });
  },
  closePaymentImage() {
    store.dispatch({
      type: "SET_PAYMENT_IMAGE",
      paymentImage: null,
    });
  },
  fetchPaymentInfo(payment_id) {
    setLoading(true);
    const promise = axios.get(`/api/payments/${payment_id}`);
    promise.then((r) => {
      store.dispatch({
        type: "SET_PAYMENT",
        payment: r.data,
      });
      setLoading(false);
    });
  },
  clearPostingError(paymentId) {
    const promise = axios.patch(`/api/payments/${paymentId}`, {payment: {post_error: null}});
    promise.then(() => actions.fetchPaymentInfo(paymentId));
    return promise;
  },
};

export default actions;
