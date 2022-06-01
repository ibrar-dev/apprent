import React from "react";
import {Provider} from "react-redux";
import SettingsApp from "./components";
import ReactDOM from "react-dom";
import store from "./store";
import actions from './actions';

const container = document.getElementById("settings-app");

if (container){
  actions.fetchBanks();
  actions.fetchAccounts();
  ReactDOM.render(
    <Provider store={store}>
      <SettingsApp/>
    </Provider>,
    container
  )
}