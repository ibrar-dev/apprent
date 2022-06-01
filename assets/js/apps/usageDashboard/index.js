import React from "react"
import {Provider} from "react-redux"
import UsageDashboardApp from "./components"
import ReactDOM from "react-dom"
import actions from './actions';
import store from "./store"

if (document.getElementById("usage-dashboard-app")) {
  actions.fetchProperties();
  actions.fetchStats();
  ReactDOM.render(
    <Provider store={store}>
      <UsageDashboardApp/>
    </Provider>,
    document.getElementById("usage-dashboard-app")
  )
}
