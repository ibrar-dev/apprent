import React from "react";
import ReactDOM from "react-dom";
import {Provider} from "react-redux";
import {BrowserRouter} from "react-router-dom";
import TenantsApp from "./components";
import store from "./store";
import actions from "./actions";

const container = document.getElementById("tenants-app");

if (container) {
  actions.fetchChargeCodes();
  actions.fetchDamages();
  actions.fetchProperties();
  actions.fetchMoveOutReasons();
  actions.fetchUnits();
  ReactDOM.render(<Provider store={store}>
    <BrowserRouter>
      <TenantsApp />
    </BrowserRouter>
  </Provider>, container);
}
