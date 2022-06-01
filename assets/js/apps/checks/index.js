import React from 'react';
import ReactDOM from 'react-dom';
import {Provider} from 'react-redux';
import ChecksApp from './components';
import store from './store';
import actions from './actions';

const container = document.getElementById('checks-app');

if (container) {
  actions.fetchChecks();
  actions.fetchInvoicings();
  actions.fetchAccounts();
  actions.fetchPayees();
  actions.fetchProperties();
  actions.fetchBankAccounts();
  ReactDOM.render(<Provider store={store}>
    <ChecksApp/>
  </Provider>, container);
}