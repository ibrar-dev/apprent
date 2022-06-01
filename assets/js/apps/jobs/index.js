import React from "react"
import {Provider} from "react-redux"
import JobsApp from "./components"
import ReactDOM from "react-dom"
import store from "./store"
import actions from './actions';

if (document.getElementById("jobs-app")) {
  actions.fetchJobs();
  actions.fetchJobTypes();
  ReactDOM.render(
    <Provider store={store}>
      <JobsApp/>
    </Provider>,
    document.getElementById("jobs-app")
  )
}
