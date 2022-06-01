import React from "react";
import {Provider} from "react-redux";
import {BrowserRouter} from "react-router-dom";
import ReactDOM from "react-dom";
import Admins from "./components";
import store from "./store";
import actions from "./actions";

if (document.getElementById("admins-app")) {
  actions.fetchAdmins();
  actions.fetchEntities();
  actions.getAddresses();
  ReactDOM.render(
    <Provider store={store}>
      <BrowserRouter>
        <Admins />
      </BrowserRouter>
    </Provider>,
    document.getElementById("admins-app"),
  );
}