import React from "react"
import {Provider} from "react-redux"
import ReportsApp from "./components"
import ReactDOM from "react-dom"
import store from "./store"
import actions from './actions';

if (document.getElementById("reports-app")) {
  actions.fetchReports();
  actions.fetchTechAdmins();
  actions.fetchProperties();
  ReactDOM.render(
    <Provider store={store}>
      <ReportsApp/>
    </Provider>,
    document.getElementById("reports-app")
  )
}
