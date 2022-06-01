import axios from "axios";
import moment from "moment";
import store from "./store";
import setLoading from "../../components/loading";
import snackbar from "../../components/snackbar";
import ajaxDownload from "../../utils/ajaxDownload";

const tenantRefresh = (promise) => {
  const {tenant} = store.getState();
  promise.finally(actions.fetchTenant.bind(null, tenant.id));
  return promise;
};

const actions = {
  fetchTenants(propertyId) {
    setLoading(true);
    if (propertyId) {
      const promise = axios.get(`/api/tenancies?property_id=${propertyId}`);
      promise.then((r) => {
        store.dispatch({
          type: "SET_TENANTS",
          tenants: r.data,
        });
        setLoading(false);
      });
      return promise;
    }
  },
  fetchTenant(id) {
    setLoading(true);
    const promise = axios.get(`/api/tenancies/${id}`);
    promise.then((r) => {
      store.dispatch({
        type: "VIEW_TENANT",
        tenant: r.data,
      });
      setLoading(false);
    });
    return promise;
  },
  fetchBankAccounts(propertyId) {
    return axios.get(`/api/bank_accounts?property_id=${propertyId}`);
  },
  searchTenants(name, property_id) {
    return axios.get(`/api/tenants?property_id=${property_id}&search=${name}`);
  },
  fetchChargeCodes() {
    axios.get("/api/charge_codes").then((response) => {
      store.dispatch({
        type: "SET_CHARGE_CODES",
        chargeCodes: response.data,
      });
    });
  },
  fetchDamages() {
    axios.get("/api/damages").then((r) => {
      store.dispatch({
        type: "SET_DAMAGES",
        damages: r.data,
      });
    });
  },
  fetchUnits(date = null) {
    let newDate;
    if (date) newDate = moment(date).format("YYYY-MM-DD");
    const url = date ? `/api/units?min&start_date=${newDate}` : "/api/units?min";
    const promise = axios.get(url);
    promise.then((r) => {
      store.dispatch({
        type: "SET_UNITS",
        units: r.data,
      });
    });
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
  fetchMoveOutReasons() {
    axios.get("/api/move_out_reasons").then((r) => {
      store.dispatch({
        type: "SET_MOVE_OUT_REASONS",
        moveOutReasons: r.data,
      });
    });
  },
  updateTenant(tenantId, params) {
    const promise = axios.patch(`/api/tenants/${tenantId}`, {tenant: params});
    promise.then(actions.fetchTenant.bind(null, params.id));
    return promise;
  },
  changeFilter({target: {value}}) {
    store.dispatch({
      type: "SET_FILTER",
      filter: value,
    });
  },
  saveInteraction(tenant, description, property) {
    const body = {visit: {description, property_id: property, tenant_id: tenant.tenant_id}};
    const promise = axios.post("/api/visits", body);
    promise.then(actions.fetchTenant.bind(null, tenant.tenant_id));
    return promise;
  },
  deleteCharge(charge) {
    return tenantRefresh(
      axios.delete(
        `/api/accounting_charges/${charge.id}?date=${charge.reversalDate}&post_month=${charge.post_month}`,
      ),
    );
  },
  hardDeleteCharge(charge) {
    return tenantRefresh(axios.delete(`/api/accounting_charges/${charge.id}?destroy=true`));
  },
  deletePayment(payment) {
    const params = {payment: {id: payment.id, status: "voided"}};
    return tenantRefresh(axios.patch(`/api/payments/${payment.id}`, params));
  },
  updatePayment(params) {
    return tenantRefresh(axios.patch(`/api/payments/${params.id}`, {payment: params}));
  },
  hardDeletePayment(payment) {
    return tenantRefresh(axios.delete(`/api/payments/${payment.id}`));
  },
  saveCharges(params) {
    return tenantRefresh(axios.post("/api/accounting_charges/", {charges: params}));
  },
  updateLease(params) {
    return tenantRefresh(axios.patch(`/api/leases/${params.id}`, {lease: params}));
  },
  updateTenancy(params) {
    return tenantRefresh(axios.patch(`/api/tenancies/${params.id}`, {tenancy: params}));
  },
  lockLease(id, params) {
    return tenantRefresh(axios.patch(`/api/leases/${id}`, {lock: params}));
  },
  unlockLease(id) {
    return tenantRefresh(axios.patch(`/api/leases/${id}`, {unlock: id}));
  },
  saveLeaseCharges(lease_id, params) {
    return tenantRefresh(axios.post("/api/lease_charges", {charges: params, lease_id}));
  },
  createLease(params) {
    return tenantRefresh(axios.post("/api/leases", {lease: params}));
  },
  createTenant(tenant) {
    setLoading(true);
    const promise = axios.post("/api/tenants", {tenant, create_new: true});
    promise.then(actions.fetchTenants.bind(null, store.getState().property.id)).catch(() => setLoading(false));
    return promise;
  },
  createPayment(params) {
    setLoading(true);
    const promise = axios.post("/api/payments", {payment: params});
    promise.then(actions.fetchTenant.bind(null, params.tenant_id));
    return promise;
  },
  createCharges(params) {
    return tenantRefresh(axios.post("/api/accounting_charges/", params))
      .then(() => snackbar({
        message: "Charges Created",
        args: {type: "success"},
      }));
  },
  updateCharge(params) {
    return tenantRefresh(axios.patch(`/api/accounting_charges/${params.id}`, {charge: params}));
  },
  prorateLease(lease_id, date) {
    return axios.get("/api/accounting_charges/" + `${lease_id}?date=${date}`);
  },
  getPaymentImageURL(id, type) {
    if (!type) return axios.get(`/api/payments/${id}?type`);
    return axios.get(`/api/payments/${id}?type=${type}`);
  },
  createLetter(tenant_id, template_id, visible) {
    setLoading(true);
    const generate = {
      tenant_ids: [tenant_id], template_id, visible, notify: false,
    };
    const promise = axios.post("/api/letter_templates", {generate});
    promise.then(() => {
      setLoading(false);
      snackbar({
        message: "Documents Created",
        args: {type: "success"},
      });
    }).catch(() => {
      setLoading(false);
      snackbar({
        message: "An Error Occurred",
        args: {type: "danger"},
      });
    });
    return tenantRefresh(promise);
  },
  createDocument(document) {
    const promise = axios.post("/api/documents", document);
    promise.then(() => {
      snackbar({
        message: "Document Created",
        args: {type: "success"},
      });
    }).catch((e) => {
      snackbar({
        message: e.response.data.error,
        args: {type: "error"},
      });
    });
    return tenantRefresh(promise);
  },
  updateDocument(document) {
    return tenantRefresh(axios.patch(`/api/documents/${document.id}`, {document}));
  },
  deleteDocument(id) {
    return tenantRefresh(axios.delete(`/api/documents/${id}`));
  },
  evict(eviction) {
    return tenantRefresh(axios.post("/api/evictions", {eviction}));
  },
  updateEviction(eviction) {
    return tenantRefresh(axios.patch(`/api/evictions/${eviction.id}`, {eviction}));
  },
  deleteEviction(eviction) {
    return tenantRefresh(axios.delete(`/api/evictions/${eviction.id}`));
  },
  deleteLease(leaseId) {
    return tenantRefresh(axios.delete(`/api/leases/${leaseId}`));
  },
  createAccount(tenantId) {
    setLoading(true);
    const promise = axios.post("/api/user_accounts", {tenant_id: tenantId});
    promise.then(() => {
      actions.getAccount(tenantId);
    });
    promise.catch((e) => {
      setLoading(false);
      snackbar({
        message: e.response.data,
        args: {type: "error"},
      });
    });
  },
  getAccount(tenantId) {
    setLoading(true);
    return axios.get(`/api/user_accounts/${tenantId}`).then((response) => {
      store.dispatch({type: "SET_ACCOUNT", account: response.data.account});
      setLoading(false);
    });
  },
  updateAccount(params) {
    setLoading(true);
    const promise = axios.patch(`/api/user_accounts/${params.id}`, {account: params});
    const {tenant} = store.getState();
    promise.then(actions.getAccount.bind(null, tenant.tenant_id));
    return promise;
  },
  lockAccount(lock) {
    const promise = axios.post("/api/locks", {lock});
    const {tenant} = store.getState();
    promise.then(actions.getAccount.bind(null, tenant.tenant_id));
    return promise;
  },
  unlockAccount(lock) {
    const promise = axios.patch(`/api/locks/${lock.id}`, {lock: {enabled: false}});
    const {tenant} = store.getState();
    promise.then(actions.getAccount.bind(null, tenant.tenant_id));
    return promise;
  },
  fetchWorkOrders(tenantId) {
    setLoading(true);
    const promise = axios.get(`/api/orders/${tenantId}?tenantsOrders`);
    promise.then((r) => {
      store.dispatch({
        type: "SET_WORK_ORDERS",
        workOrders: r.data,
      });
      setLoading(false);
    });
    promise.catch(() => {
      setLoading(false);
    });
  },
  getTenantPoints(tenantId) {
    const promise = axios.get(`/api/rewards/${tenantId}`);
    promise.then((r) => {
      store.dispatch({
        type: "SET_TENANT_POINTS",
        points: r.data,
      });
    });
  },
  getTenantAwardHistory(tenantId) {
    const promise = axios.get(`/api/rewards/${tenantId}?awardHistory`);
    promise.then((r) => {
      store.dispatch({
        type: "SET_TENANT_AWARD_HISTORY",
        awards: r.data,
      });
    });
  },
  getTenantPurchaseHistory(tenantId) {
    const promise = axios.get(`/api/rewards/${tenantId}?purchaseHistory`);
    promise.then((r) => {
      store.dispatch({
        type: "SET_TENANT_PURCHASE_HISTORY",
        purchases: r.data,
      });
    });
  },
  getAwardTypes() {
    const promise = axios.get("/api/rewards?awardType");
    promise.then((r) => {
      store.dispatch({
        type: "SET_TENANT_AWARD_TYPES",
        types: r.data,
      });
    });
  },
  getPrizes() {
    const promise = axios.get("/api/prizes");
    promise.then((r) => {
      store.dispatch({
        type: "SET_TENANT_PRIZES",
        prizes: r.data,
      });
    });
  },
  purchasePrize(purchase, tenant_id) {
    const promise = axios.post("/api/rewards", {newPurchase: purchase});
    promise.then(() => {
      this.getTenantPurchaseHistory(tenant_id);
      this.getTenantPoints(tenant_id);
      snackbar({
        message: "Award added",
        args: {type: "success"},
      });
    });
  },
  addAward(award, tenant_id) {
    const promise = axios.post("/api/rewards", {newAward: award});

    promise.then(() => {
      this.getTenantAwardHistory(tenant_id);
      this.getTenantPoints(tenant_id);
      snackbar({
        message: "Award added",
        args: {type: "success"},
      });
    });
  },
  deleteAward(award_id, tenant_id) {
    const promise = axios.delete(`/api/rewards/${award_id}`);
    promise.then(() => {
      this.getTenantAwardHistory(tenant_id);
      snackbar({
        message: "Award deleted",
        args: {type: "success"},
      });
    });
  },
  sendResetPasswordEmail(email) {
    return axios.post("/api/user_accounts", {reset_password: email});
  },
  sendWelcomeEmail(account_id) {
    return axios.patch(`/api/user_accounts/${account_id}`, {send_welcome: true});
  },
  setFilters(name, value) {
    const {filters} = store.getState();
    store.dispatch({
      type: "SET_FILTERS",
      filters: {...filters, [name]: value},
    });
  },
  removeFilter(name) {
    const {filters} = store.getState();
    delete filters[name];
    store.dispatch({
      type: "SET_FILTERS",
      filters: {...filters},
    });
  },
  clearFilters() {
    store.dispatch({
      type: "SET_FILTERS",
      filters: {},
    });
  },
  setProperty(property) {
    store.dispatch({
      type: "SET_PROPERTY",
      property,
    });
    actions.fetchTenants(property.id);
  },
  sendEmail(params) {
    setLoading(true);
    const data = new FormData();
    Object.keys(params).forEach((key) => {
      const value = params[key];
      if (Array.isArray(value)) {
        value.forEach((v) => data.append(`resident_email[${key}][]`, v));
      } else {
        data.append(`resident_email[${key}]`, params[key]);
      }
    });
    const promise = axios.post("/api/resident_emails", data);
    promise.then(() => {
      setLoading(false);
      actions.fetchTenant(params.tenant_id);
      snackbar({
        message: "Email Sent to Resident",
        args: {type: "success"},
      });
    });
    promise.catch(() => {
      setLoading(false);
      snackbar({
        message: "Email NOT Sent to Resident",
        args: {type: "error"},
      });
    });
    return promise;
  },
  updateOccupant(occupant, tenant_id) {
    setLoading(true);
    const promise = axios.patch(`/api/occupants/${occupant.id}`, {occupant});
    promise.then(() => {
      snackbar({
        message: "Occupant Saved",
        args: {type: "success"},
      });
      setLoading(false);
      actions.fetchTenant(tenant_id);
    });
    promise.catch(() => {
      setLoading(false);
      snackbar({
        message: "Occupant Not Saved",
        args: {type: "error"},
      });
    });
    return promise;
  },
  createOccupant(occupant, tenant_id) {
    setLoading(true);
    const promise = axios.post("/api/occupants", {occupant});
    promise.then(() => {
      snackbar({
        message: "Occupant Saved",
        args: {type: "success"},
      });
      setLoading(false);
      actions.fetchTenant(tenant_id);
    });
    promise.catch((r) => {
      setLoading(false);
      snackbar({
        message: r.response.data.error,
        args: {type: "error"},
      });
    });
    return promise;
  },
  deletePerson(id) {
    const promise = axios.delete(`/api/occupants/${id}`);
    promise.then(() => {
      snackbar({
        message: "Person deleted",
        args: {type: "success"},
      });
    });
    return tenantRefresh(promise);
  },
  markNSF(nsf) {
    const promise = axios.post("/api/payments", nsf);
    promise.then(() => {
      snackbar({
        message: "Payment marked as NSF",
        args: {type: "success"},
      });
    });
    promise.catch(() => {
      snackbar({
        message: "Payment NOT-marked as NSF, please contact a support specialist",
        args: {type: "error"},
      });
    });
    return tenantRefresh(promise);
  },
  fetchTemplates(id) {
    const promise = axios.get(`/api/letter_templates?property_id=${id}`);
    promise.then((r) => {
      store.dispatch({
        type: "SET_PROPERTY_TEMPLATES",
        data: r.data,
      });
    });
  },
  addTenant(tenant, lease_id) {
    const promise = axios.post("/api/tenants", {tenant, lease_id});
    promise.then(() => {
      snackbar({
        message: "Tenant Added",
        args: {type: "success"},
      });
    }).catch((r) => {
      snackbar({
        message: r.response.data.error,
        args: {type: "error"},
      });
    });
    return tenantRefresh(promise);
  },
  screenPerson(screening) {
    const promise = axios.post("/api/screenings", {screening});
    promise.then(() => {
      snackbar({
        message: "Screening request submitted",
        args: {type: "success"},
      });
    }).catch((r) => {
      snackbar({
        message: r.response.data.error,
        args: {type: "error"},
      });
    });
    return tenantRefresh(promise);
  },
  approveScreening(id) {
    setLoading(true);
    const promise = axios.patch(`/api/screenings/${id}`, {approve: true});
    promise.then(() => {
      snackbar({
        message: "Approved and added to lease",
        args: {type: "success"},
      });
    }).catch((r) => {
      snackbar({
        message: r.response.data.error,
        args: {type: "error"},
      });
    });
    return tenantRefresh(promise);
  },
  deleteScreening(id) {
    setLoading(true);
    const promise = axios.delete(`/api/screenings/${id}`);
    promise.then(() => {
      snackbar({
        message: "Rejected",
        args: {type: "success"},
      });
    }).catch((r) => {
      snackbar({
        message: r.response.data.error,
        args: {type: "error"},
      });
    });
    return tenantRefresh(promise);
  },
  attachBlueMoonLease(lease_form) {
    setLoading(true);
    const promise = axios.post("/api/lease_forms", {lease_form});
    promise.then(() => {
      snackbar({
        message: "Got BlueMoon lease",
        args: {type: "success"},
      });
    }).catch((r) => {
      snackbar({
        message: r.response.data.error,
        args: {type: "error"},
      });
    });
    return tenantRefresh(promise);
  },
  get_mailing_list_csv(property_id) {
    ajaxDownload(`/api/mailings/${property_id}?type=new`, "users.csv");
  },
  createPet(pet) {
    return tenantRefresh(axios.post("/api/pets", {pet}));
  },
  updatePet(pet) {
    return tenantRefresh(axios.patch(`/api/pets/${pet.id}`, {pet}));
  },
  createVehicle(vehicle) {
    return tenantRefresh(axios.post("/api/vehicles", {vehicle}));
  },
  updateVehicle(vehicle) {
    return tenantRefresh(axios.patch(`/api/vehicles/${vehicle.id}`, {vehicle}));
  },
  downloadResidentLedger(tenant_id, lease_id) {
    ajaxDownload(`/api/tenancies/${tenant_id}?lease_id=${lease_id}&export`, `ResidentLedgerExport${moment().format("YYYY_MM_DD")}.pdf`);
  },
  syncTenantExternalId(tenantId) {
    setLoading(true);
    const promise = axios.patch(`/api/tenants/${tenantId}`, {sync: true});
    promise.then((r) => {
      if (r.data.success) {
        actions.fetchTenant(tenantId);
        setLoading(false);
      } else {
        snackbar({
          message: r.data.error,
          args: {type: "error"},
        });
        setLoading(false);
      }
    });
    return promise;
  },
  setTenantEmailAsValid(id) {
    setLoading(true);
    return axios.post(`/api/tenants/${id}/clear_bounces`)
      .then(() => actions.fetchTenant(id))
      .catch(() => snackbar({
        message: "An error occurred while clearing bounces for this email.",
        args: {type: "error"},
      }))
      .finally(() => setLoading(false));
  },
};

export default actions;
