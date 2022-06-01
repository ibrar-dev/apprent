import axios from 'axios';
import moment from 'moment';
import store from './store';
import setLoading from '../../components/loading';
import snackbar from '../../components/snackbar';
import ajaxDownload from "../../utils/ajaxDownload";

const actions = {
  fetchProperties() {
    setLoading(true);
    axios.get('/api/property_meta').then(r => {
      store.dispatch({
        type: 'SET_PROPERTIES',
        properties: r.data
      });
      const {property} = store.getState();
      if (!property.id) return actions.viewProperty(r.data[0]);
    });
  },
  viewProperty(property) {
    store.dispatch({
      type: 'SET_PROPERTY',
      property
    });
    const {year} = store.getState();
    return actions.fetchBudget(year || moment().get('year'));
  },
  downloadTemplate() {
    const {property} = store.getState();
    ajaxDownload(`/api/budgets?property_id=${property.id}&template=true`, `${property.name}_budget_workshop.csv`);
  },
  saveBudget(lines) {
    setLoading(true);
    const promise = axios.post(`/api/budgets`, {lines});
    promise.then(() => {
      snackbar({
        message: 'Budget Uploaded',
        args: {type: 'success'}
      });
      actions.fetchBudget(store.getState().year);
    });
    return promise;
  },
  uploadBudget(budget_import) {
    const {property} = store.getState();
    const promise = axios.post(`/api/budgets?property_id=${property.id}`, {budget_import});
    promise.then(() => {
      snackbar({
        message: 'Budget Uploaded',
        args: {type: 'success'}
      });
    });
    promise.catch(e => {
      snackbar({
        message: e.response.data,
        args: {type: 'error'}
      });
    })
  },
  fetchBudget(year) {
    const {property} = store.getState();
    if (property && property.id) {
      setLoading(true);
      const promise = axios.get(`/api/budgets?property_id=${property.id}&year=${year}&with_cats=true`);
      promise.then(r => {
        setLoading(false);
        store.dispatch({
          type: 'SET_BUDGET',
          budget: r.data
        })
      });
      promise.catch(e => {
        setLoading(false);
        snackbar({
          message: e.response.data,
          args: {type: 'error'}
        });
      })
    } else {
      snackbar({
        message: "No Property Selected",
        args: {type: 'error'}
      });
    }
  },
  fetchDetailedAccount(year, accountId) {
    setLoading(true);
    const {property} = store.getState();
    const promise = axios.get(`/api/budgets/${accountId}?property_id=${property.id}&year=${year}`);
    promise.then(() => {
      setLoading(false);
    }).catch(e => {
      setLoading(false);
      snackbar({
        message: e.response.data,
        args: {type: 'error'}
      });
    });
    return promise;
  },
  fetchYears() {
    const {property} = store.getState();
    const promise = axios.get(`/api/budgets?show_years=true&property_id=${property.id}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_YEARS',
        years: r.data
      })
    });
    promise.catch(e => {
      snackbar({
        message: e.response.data,
        args: {type: 'error'}
      });
    })
  },
  setYear(year) {
    store.dispatch({
      type: 'SET_YEAR',
      year: year
    });
    actions.fetchBudget(year);
  },
  updateLines(account, budget_lines) {
    setLoading(true);
    const year = moment(budget_lines[0].month).format("YYYY");
    const promise = axios.patch(`/api/budget_lines/${account}`, {budget_lines});
    promise.then(() => {
      actions.fetchBudget(year);
      snackbar({
        message: 'Budget updated',
        args: {type: 'success'}
      });
    });
    promise.catch(e => {
      setLoading(false);
      snackbar({
        message: e.response.data,
        args: {type: 'error'}
      });
    })
  },
  fetchImports() {
    const {property} = store.getState();
    const promise = axios.get(`/api/budgets?property_id=${property.id}`);
    promise.then(r => {
      store.dispatch({
        type: 'SET_IMPORTS',
        imports: r.data
      })
    });
    promise.catch(e => {
      snackbar({
        message: e.response.data,
        args: {type: 'error'}
      });
    })
  },
  beginImport(import_id) {
    const promise = axios.patch(`/api/budgets/${import_id}`);
    promise.then(() => {
      actions.fetchImports();
      snackbar({
        message: "Import Started",
        args: {type: 'success'}
      });
    });
    promise.catch(e => {
      snackbar({
        message: e.response.data,
        args: {type: 'error'}
      });
    })
  },
  closeYear(year, property_id) {
    setLoading(true);
    const promise = axios.patch(`/api/budget_lines/${property_id}?year=${year}&close_year=true`);
    promise.then(() => {
      setLoading(false);
      snackbar({
        message: "Year Closed",
        args: {type: 'success'}
      });
    });
    promise.catch(e => {
      setLoading(false);
      snackbar({
        message: e.response.data,
        args: {type: 'error'}
      });
    });
  },
  closeMonth(month) {
    setLoading(true);
    const {property} = store.getState();
    const promise = axios.patch(`/api/budget_lines/${property.id}?month=${month}`);
    promise.then(() => {
      setLoading(false);
      actions.fetchBudget(moment(month).format("YYYY"));
      snackbar({
        message: "Month Closed",
        args: {type: 'success'}
      });
    });
    promise.catch(e => {
      setLoading(false);
      snackbar({
        message: e.response.data,
        args: {type: 'error'}
      });
    });
  },
  // //PLAYGROUND
  // fetchPlayground() {
  //   const {property} = store.getState();
  //   const promise = axios.get(`/api/account_categories`);
  //   promise.then(r => {
  //     store.dispatch({
  //       type: 'SET_PLAYGROUND',
  //       playground: r.data
  //     })
  //   })
  // },
  // updateAccount(account) {
  //   const promise = axios.patch(`/api/accounts/${account.id}`, {account});
  //   promise.then(() => {
  //     snackbar({
  //       message: "Account Updated",
  //       args: {type: 'success'}
  //     });
  //     actions.fetchPlayground();
  //   });
  //   promise.catch(e => {
  //     snackbar({
  //       message: e.response.data,
  //       args: {type: 'error'}
  //     });
  //   });
  // },
  // updateCategory(accountCategory) {
  //   const promise = axios.patch(`/api/account_categories/${accountCategory.id}`, {accountCategory});
  //   promise.then(() => {
  //     snackbar({
  //       message: "Account Category Updated",
  //       args: {type: 'success'}
  //     });
  //     actions.fetchPlayground();
  //   });
  //   promise.catch(e => {
  //     snackbar({
  //       message: e.response.data,
  //       args: {type: 'error'}
  //     });
  //   });
  // }
};

export default actions