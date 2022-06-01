import React from 'react';
import ReactDOM from 'react-dom';
import {Provider} from 'react-redux';
import BankAccountsApp from './components';
import store from './store';
import actions from './actions';

const container = document.getElementById('bank-accounts-app');

if (container) {
  actions.fetchBankAccounts();
  actions.fetchAccounts();
  actions.fetchProperties();
  ReactDOM.render(<Provider store={store}>
    <BankAccountsApp/>
  </Provider>, container);
}