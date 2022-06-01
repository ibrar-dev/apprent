import React from "react"
import {Provider} from "react-redux"
import PropertyReportsApp from "./components"
import ReactDOM from "react-dom"
import store from "./store"
import actions from './actions';

if (document.getElementById("propertyReport-app")) {
  actions.fetchProperties();
  ReactDOM.render(
    <Provider store={store}>
        <PropertyReportsApp />
    </Provider>,
    document.getElementById("propertyReport-app")
  )
}
