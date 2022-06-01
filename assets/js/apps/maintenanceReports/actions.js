import axios from 'axios';
import store from './store';
import setLoading from '../../components/loading';
import snackbar from '../../components/snackbar';

const actions = {
  fetchReports() {
    axios.get('/api/maintenance_reports').then(r => {
      store.dispatch({
        type: 'SET_REPORTS',
        reports: r.data
      })
    });
  },
  fetchProperties() {
    const promise = axios.get('/api/properties?min');
    promise.then(r => {
      store.dispatch({
        type: 'SET_PROPERTIES',
        properties: r.data
      })
    })
  },
  fetchUnits(property_id) {
    const promise = axios.get(`/api/units?property_id=${property_id}`);
    promise.then(r => {
      this.fetchWorkOrders(property_id, "unassigned, assigned")
      store.dispatch({
        type: 'SET_UNITS',
        units: r.data
      })
    })
  },
  fetchWorkOrders(property_id, type) {
    const promise = axios.get(`/api/orders?type=${type}&property_id=${property_id}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_ORDERS',
        orders: r.data
      })
    })
  },
  fetchDailyReport() {
    const promise = axios.get('/api/info_for_daily_report?daily_report');
    promise.then(r => {
      store.dispatch({
        type: 'SET_DAILY_REPORT',
        report: r.data
      })
    })
  },
  submitDailyReport(notes, adminIDs) {
    const body = {notes: notes, admin_ids: adminIDs};
    const promise = axios.post('/api/info_for_daily_report', body);
    return promise;
  },
  fetchMaintenanceTechs() {
    setLoading(true);
    const promise = axios.get('/api/techs?min');
    promise.then(r => {
      store.dispatch({
        type: 'SET_MIN_TECHS',
        techs: r.data
      })
      setLoading(false);
    });
    promise.catch(() =>{
      setLoading(false);
      snackbar({
        message: 'Unable to get Maintenance Techs',
        args: {type: 'error'}
      })
    })
  },
  fetchMaintenanceTechsInfo(techs, startDate, endDate, selectedProperties) {
    setLoading(true);
    const params = {techs, startDate, endDate, selectedProperties}
    const promise = axios.post(`/api/maintenance_reports?techReport`, {params});
    promise.then(r => {
      const techs = store.getState().maintenanceTechs;
      store.dispatch({
        type: 'SET_DETAILED_TECHS',
        techs: {...techs, detailed: r.data}
      });
      setLoading(false);
    });
    promise.catch(() =>{
      setLoading(false);
      snackbar({
        message: 'Unable to get Detailed Tech Info',
        args: {type: 'error'}
      })
    })
  },
  fetchTechAdmins() {
    const promise = axios.get('/api/admins?fetchTechs');
    promise.then(r => {
      store.dispatch({
        type: 'SET_TECHS',
        techs: r.data
      })
    })
  },
  fetchAdminSixMonths(property_id) {
    setLoading(true);
    const promise = axios.get(`/api/maintenance_reports?property_id=${property_id}&six_months_stats=true`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_SIX_MONTH_STATS',
        stats: r.data
      });
      setLoading(false);
    });
    return promise;
  },
  fetchSixMonthStats(techId) {
    setLoading(true);
    const promise = axios.get(`/api/maintenance_reports?admin_id=${techId}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_SIX_MONTH_STATS',
       stats: r.data
      });
      setLoading(false);
    });
    return promise;
  },
  fetchOpenHistories(startDate, endDate) {
    setLoading(true);
    const promise = axios.get(`/api/open_histories?startDate=${startDate}&endDate=${endDate}`);
    promise.then(r => {
      setLoading(false);
      store.dispatch({
        type: 'SET_OPEN_HISTORIES',
        openHistories: r.data
      });
    });
    promise.catch(() => {
      setLoading(false);
      snackbar({
        message: 'Unable to get history',
        args: {type: 'error'}
      })
    })
  },
  fetchCompletedOrders(startDate, endDate) {
    setLoading(true);
    const promise = axios.get(`/api/maintenance_reports?completed&startDate=${startDate}&endDate=${endDate}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_COMPLETED_ORDERS',
        completed: r.data
      })
      setLoading(false)
    });
    promise.catch(() => {
      setLoading(false);
      snackbar({
        message: 'Unable to get completed orders',
        args: {type: 'error'}
      })
    })
  },
  fetchCategories(startDate, endDate) {
    setLoading(true);
    const promise = axios.get(`/api/maintenance_reports?categories&startDate=${startDate}&endDate=${endDate}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_CATEGORIES_ORDERS',
        orders: r.data
      });
      setLoading(false);
    });
    promise.catch(() => {
      setLoading(false);
      snackbar({
        message: 'Unable to get categories history',
        args: {type: 'error'}
      })
    })
  },
  fetchCategoriesCompleted(startDate, endDate) {
    setLoading(true);
    const promise = axios.get(`/api/maintenance_reports?categoriesCompleted&startDate=${startDate}&endDate=${endDate}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_CATEGORIES_COMPLETED',
        orders: r.data
      });
      setLoading(false);
    });
    promise.catch(() => {
      setLoading(false);
      snackbar({
        message: 'Unable to get categories completed',
        args: {type: 'error'}
      })
    })
  },
  fetchKatsReport(date) {
    setLoading(true);
    const promise = axios.get(`/api/property_report?open_make_ready_report=true&date=${date}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_KATS_REPORT',
        data: r.data
      });
      setLoading(false);
    });
    promise.catch(() => {
      setLoading(false);
      snackbar({
        message: 'Unable to fetch Kats Report',
        args: {type: 'error'}
      })
    });
  },
  fetchDatedReport(type, startDate, endDate) {
    setLoading(true);
    const promise = axios.get(`/api/maintenance_reports?${type}&startDate=${startDate}&endDate=${endDate}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_REPORT_DATA',
        data: r.data
      });
      setLoading(false);
    });
    promise.catch(() => {
      setLoading(false);
      snackbar({
        message: 'Unable to fetch Report Data',
        args: {type: 'error'}
      })
    });
  }
};

export default actions;
