import React from "react";
import {Provider} from "react-redux";
import {BrowserRouter} from "react-router-dom";
import ReactDOM from "react-dom";
import WorkOrdersApp from "./components";
import store from "./store";
import actions from "./actions";

const container = document.getElementById("work-orders-app");

if (container) {
  actions.fetchOrders();
  actions.fetchSubCategories();
  actions.fetchTechs();
  actions.fetchCategories();
  actions.fetchEveryone();
  ReactDOM.render(
    <Provider store={store}>
      <BrowserRouter>
        <WorkOrdersApp />
      </BrowserRouter>
    </Provider>,
    container,
  );
}
