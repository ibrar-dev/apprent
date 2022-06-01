import React from "react";
import {Provider} from "react-redux";
import ReactDOM from "react-dom";
import Navbar from "./components";
import store from "./store";
import actions from "./actions";

const container = document.getElementById("navbar-app");

if (container) {
  actions.fetchAdmin(window.user.id);
  ReactDOM.render(
    <Provider store={store}>
      <Navbar />
    </Provider>,
    container,
  );
}
