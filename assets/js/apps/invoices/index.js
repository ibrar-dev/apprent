import React from "react";
import {Provider} from "react-redux";
import {BrowserRouter} from 'react-router-dom';
import InvoicesApp from "./components";
import ReactDOM from "react-dom";
import store from "./store";
import actions from './actions';

if (document.getElementById("invoices-app")) {
  actions.fetchAccounts();
  actions.fetchBankAccounts();
  actions.fetchInvoices();
  actions.fetchPayees();
  actions.fetchProperties();
  ReactDOM.render(
    <Provider store={store}>
      <BrowserRouter>
        <InvoicesApp/>
      </BrowserRouter>
    </Provider>,
    document.getElementById("invoices-app")
  )
}
