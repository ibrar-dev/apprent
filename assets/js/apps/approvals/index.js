import React from "react";
import ReactDOM from "react-dom";
import {Provider} from "react-redux";
import {BrowserRouter} from "react-router-dom";
import ApprovalsApp from "./components";
import store from "./store";
import actions from "./actions";

const container = document.getElementById("approvals-app");

if (container) {
  actions.fetchProperties();
  actions.fetchVendors();
  actions.fetchAdmins();
  actions.fetchEveryone();
  ReactDOM.render(
    <Provider store={store}>
      <BrowserRouter>
        <ApprovalsApp />
      </BrowserRouter>
    </Provider>,
    container,
  );
}
