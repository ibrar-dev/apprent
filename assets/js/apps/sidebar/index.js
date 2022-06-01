import React from "react";
import {Provider} from "react-redux";
import ReactDOM from "react-dom";
import Sidebar from "./components";
import store from "./store";
import actions from "./actions";

const container = document.getElementById("sidebar-app");

if (container) {
  actions.initializeChannel();
  ReactDOM.render(
    <Provider store={store}>
      <Sidebar />
    </Provider>,
    container,
  );
}
