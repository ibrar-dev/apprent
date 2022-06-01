import React from "react"
import {Provider} from "react-redux"
import ExportsApp from "./components"
import ReactDOM from "react-dom"
import store from "./store"
import actions from './actions';

if (document.getElementById("exports-app")) {
  actions.fetchExports();
  ReactDOM.render(
    <Provider store={store}>
      <ExportsApp/>
    </Provider>,
    document.getElementById("exports-app")
  )
}
