import React from "react";
import {Provider} from "react-redux";
import ReactDOM from "react-dom";
import PurchasesApp from "./components";
import store from "./store";
import actions from "./actions";

const container = document.getElementById("redemptions-app");

if (container) {
  actions.fetchPurchases();
  ReactDOM.render(
    <Provider store={store}>
      <PurchasesApp />
    </Provider>,
    container,
  );
}
