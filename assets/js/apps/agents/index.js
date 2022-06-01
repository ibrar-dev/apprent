import React from "react"
import {Provider} from "react-redux"
import AgentsApp from "./components/agentsApp"
import ReactDOM from "react-dom"
import store from "./store"

if (document.getElementById("agents-app")) {
  ReactDOM.render(
    <Provider store={store}>
      <AgentsApp />
    </Provider>,
    document.getElementById("agents-app")
  )
}
