import axios from 'axios';
import store from './store';
import setLoading from '../../components/loading';
import snackbar from "../../components/snackbar";
import ajaxDownload from "../../utils/ajaxDownload";

const actions = {
  fetchTemplates() {
    axios.get('/api/report_templates').then(r => {
      store.dispatch({
        type: 'SET_TEMPLATES',
        templates: r.data
      });
    });
  },
  fetchProperties() {
    axios.get('/api/property_meta').then(r => {
      store.dispatch({
        type: 'SET_PROPERTIES',
        properties: r.data
      });
    });
  },
  fetchAccountDetail(accountId, propertyIds, start_date, end_date, book) {
    const property_ids = propertyIds.join(',');
    const params = end_date ? {start_date, property_ids, end_date, book} : {date: start_date, property_ids, book};
    setLoading(true);
    const promise = axios.get(`/api/accounting_reports/${accountId}`, {params});
    promise.finally(() => setLoading(false));
    return promise;
  },
  accountDetailExcel(accountId, propertyIds, start, end, book) {
    const property_ids = propertyIds.join(',');
    const url = end ? `/api/accounting_reports/${accountId}?start=${start}&end=${end}&book=${book}&property_ids=${property_ids}&excel=detail` : `/api/accounting_reports/${accountId}?start=${start}&book=${book}&property_ids=${property_ids}&excel=detail`;
    ajaxDownload(url)
  },
  exportExcel({id, property_ids, start, end, suppressZeros, book, glAccountId}) {
    const url = `/api/accounting_reports/${id}?property_ids=${property_ids}&start=${start.format('YYYY-MM-DD')}&end=${end.format('YYYY-MM-DD')}&book=${book}&suppress_zeros=${suppressZeros}&excel=${glAccountId}`;
    ajaxDownload(url);
  },
  runReport(params) {
    store.dispatch({type: 'SET_REPORT_TYPE', report: params});
    setLoading(true);
    const promise = axios.post('/api/accounting_reports', {report: params});
    promise.then(r => {
      store.dispatch({
        type: 'SET_REPORT',
        report: r.data
      });
    }).catch(e => {
      snackbar({
        message: e.response.data.error,
        args: {type: 'error'}
      });
    });
    promise.finally(() => setLoading(false));
    return promise;
  }
};

export default actions;
