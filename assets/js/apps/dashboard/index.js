import React from "react"
import {Provider} from "react-redux"
import DashboardApp from "./components"
import ReactDOM from "react-dom"
import actions from './actions';
import store from "./store"

if (document.getElementById("dashboard-app")) {
  // actions.fetchEvents();
  actions.fetchProperties();
  // actions.fetchPropertyReport();
    ReactDOM.render(
      <Provider store={store}>
        <DashboardApp />
      </Provider>,
      document.getElementById("dashboard-app")
    )
}
