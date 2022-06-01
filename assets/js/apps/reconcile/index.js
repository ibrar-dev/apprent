import React from 'react';
import ReactDOM from 'react-dom';
import {BrowserRouter} from "react-router-dom";
import ReconciliationApp from './components';
import actions from './actions';
import {Provider} from 'react-redux';
import store from './store';

const container = document.getElementById('reconciliation-app');

if (container) {
  actions.fetchBankAccounts()
  .then(() => actions.fetchPostings(store.getState().bankAccounts[0].id))
  ReactDOM.render(
    <Provider store={store}>
      <BrowserRouter>
        <ReconciliationApp/>
      </BrowserRouter>
      </Provider>,
      container);
}
