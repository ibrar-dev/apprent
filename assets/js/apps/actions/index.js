import React from "react";
import {Provider} from "react-redux";
import ActionsApp from "./components";
import ReactDOM from "react-dom"
import store from "./store"
import actions from './actions';

if (document.getElementById("actions-app")) {
  ReactDOM.render(
    <Provider store={store}>
      <ActionsApp/>
    </Provider>,
    document.getElementById("actions-app")
  )
}