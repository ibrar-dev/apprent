import React from "react"
import {Provider} from "react-redux"
import PropertiesApp from "./components"
import ReactDOM from "react-dom"
import store from "./store"
import actions from './actions';

if (document.getElementById("properties-app")) {
  actions.fetchProperties();
  actions.fetchAccounts();
  ReactDOM.render(
    <Provider store={store}>
      <PropertiesApp/>
    </Provider>,
    document.getElementById("properties-app")
  )
}
