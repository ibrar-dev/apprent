import axios from 'axios';
import store from "./store"
import setLoading from '../../components/loading';
import snackbar from '../../components/snackbar';
import moment from 'moment';
import ajaxDownload from "../../utils/ajaxDownload";
import {toQueryString} from "../../utils";

//Add to this array to get the current date as the state is switched to the report
const datedReportsArray = ['delinquency', 'rent_roll', 'daily_deposit', 'expiring_leases'];
const resolvePromiseOne = ['admin_actions', 'move_outs', 'boxscore'];

const actions = {
  setSkeleton(value) {
    store.dispatch({
      type: 'SET_SKELETON',
      skeleton: value
    })
  },
  fetchProperties() {
    setLoading(true);
    const promise = axios.get('/api/property_meta');
    promise.then(r => {
        store.dispatch({
          type: 'SET_PROPERTIES',
          properties: r.data
        });
        setLoading(false);
        const {property} = store.getState();
        if (!property.id) return actions.setProperty(r.data[0] || {});
        r.data.some(p => {
          if (p.id === property.id) {
            actions.setProperty(p);
            return true;
          }
        });
      }
    );
    return promise;
  },
  setPayers(data) {
    store.dispatch({
      type: 'SET_PAYERS',
      payers: data.map((d, i) => ({name: d.payee, id: i}))
    });
  },
  setProperty(property) {
    store.dispatch({
      type: 'SET_PROPERTY',
      property
    });
    const {report} = store.getState();
    if (report && report.length >= 1) actions.setReport(report);
  },
  setReport(report) {
    store.dispatch({
      type: 'SET_REPORT',
      report: report
    });
    store.dispatch({
      type: 'SET_DATA',
      reportData: []
    });
    const {property} = store.getState();
    if (!property.id) return Promise.resolve(1);
    if (resolvePromiseOne.includes(report)) return Promise.resolve(1);
    if (datedReportsArray.includes(report)) {
      return actions.fetchDatedReport(report, property, moment().format('YYYY-MM-DD'));
    }
    if (report === 'gpr') {
      return actions.fetchGPR({
        property_id: property.id,
        date: moment().format('YYYY-MM-DD'),
        post_month: moment().startOf('month').format('YYYY-MM-DD')
      });
    }
    if (report === 'aging') {
      const promise = actions.fetchReport(report, property);
      promise.then(r => actions.setPayers(r.data));
      return promise;
    }

    if(report === 'resident_directory'){
      const promise = actions.fetchResidentDirectory(property);
      return promise;
    }
    return actions.fetchReport(report, property);
  },
  fetchResidentDirectory(property){
    const promise = axios.get(`/api/property_report?property_id=${property.id}&resident_directory=true`)
    promise.then(r => {
      store.dispatch({
        type: 'SET_RESIDENT_DIRECTORY',
        residentsData: r.data
      })
    })
    return promise;
  },
  fetchGPR(params) {
    setLoading(true);
    const url = '/api/property_report' + toQueryString({...params, gpr: true});
    if (params.excel) {
      ajaxDownload(url);
      setLoading(false);
      return;
    }
    const promise = axios.get(url);
    promise.then(r => {
      store.dispatch({
        type: 'SET_DATA',
        reportData: r.data
      });
      setLoading(false)
    }).catch(() => {
      setLoading(false);
      snackbar({
        message: 'Unable to get report',
        args: {type: 'error'}
      })
    });
    return promise;
  },
  fetchDatedReport(type, property, date) {
    setLoading(true);
    const promise = axios.get(`/api/property_report?property_id=${property.id}&${type}=true&date=${date}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_DATA',
        reportData: r.data
      });
      setLoading(false)
    }).catch(() => {
      setLoading(false);
      snackbar({
        message: 'Unable to get report',
        args: {type: 'error'}
      })
    });
    return promise;
  },
  clearReportData() {
    return new Promise((resolve) => {
      store.dispatch({
        type: 'SET_DATA',
        reportData: []
      });
      resolve();
    })
  },
  fetchAdminAction(admin_id, start_date, end_date) {
    return axios.get(`/api/property_report?admin_id=${admin_id}&admin_payments_and_charges&start_date=${start_date}&end_date=${end_date}`)
  },
  fetchAdmins() {
    return axios.get('/api/admins');
  },
  fetchReport(type, property) {
    setLoading(true);
    const promise = axios.get(`/api/property_report?property_id=${property.id}&${type}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_DATA',
        reportData: r.data
      });
      setLoading(false);
    }).catch(() => {
      setLoading(false);
      snackbar({
        message: 'Unable to get report',
        args: {type: 'error'}
      })
    });
    return promise;
  },
  fetchBoxScore(type, dates) {
    actions.setSkeleton(true);
    const {property} = store.getState();
    const promise = axios.get(`/api/property_report?box_score&property_id=${property.id}&type=${type}&dates=${dates.join(',')}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_DATA',
        reportData: r.data
      });
      actions.setSkeleton(false);
    });
    promise.catch(() => {
      setLoading(false);
      snackbar({
        message: 'Unable to get report',
        args: {type: 'error'}
      })
      actions.setSkeleton(false);
    });
  },
  setDetailedData(data) {
    store.dispatch({
      type: 'SET_DETAILED_DATA',
      data
    })
  },
  fetchNewBoxScore(dates){
    const {property} = store.getState();
    const promise = axios.get(`/api/property_report?property_id=${property.id}&new_box_score=true&start_date=${dates.start_date}&end_date=${dates.end_date}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_NEW_BOX_SCORE',
        new_box_score: r.data,
      });
    })
  },
  fetchUnitStatus(end_date = null){
    const {property} = store.getState();
    const promise = axios.get(`/api/property_report?property_id=${property.id}&unit_status=true&end_date=${end_date}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_UNIT_STATUS',
        unit_status: r.data
      });
    })
  },
  fetchMultiDateReport(type, property, starDate, endDate) {
    setLoading(true);
    const promise = axios.get(`/api/property_report?property_id=${property.id}&${type}&start_date=${starDate}&end_date=${endDate}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_DATA',
        reportData: r.data
      });
      setLoading(false);
    });
    promise.catch(() => {
      setLoading(false);
      snackbar({
        message: 'Unable to get report',
        args: {type: 'error'}
      })
    });
  },
  setMode(mode) {
    store.dispatch({
      type: 'SET_MODE',
      mode: mode
    })
  },
  saveInteraction(id, description, property) {
    const date = new Date();
    const body = {visit: {description: description, property_id: property, tenant_id: id, delinquency: date}};
    const promise = axios.post('/api/visits', body);
    promise.then(() => {
      snackbar({
        message: 'Memo Saved',
        args: {type: 'success'}
      })
    });
  },
  downloadDQExcel(property_id, filters, date, ar) {
    ajaxDownload(`/api/property_report?property_id=${property_id}&filters=${filters}&ar=${ar}&delinquency=true&date=${date}&download=excel`, `DQExport.xlsx`)
  },
  downloadRentRollCSV(property_id, date) {
    ajaxDownload(`/api/property_report?property_id=${property_id}&rent_roll=true&date=${date}&download=excel`, `RentRollExport.xlsx`);
  }
};

export default actions;
