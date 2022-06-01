import React from "react"
import {Provider} from "react-redux"
import ClosingsApp from "./components"
import ReactDOM from "react-dom"
import store from "./store"
import actions from './actions';

const container = document.getElementById("closings-app");

if (container) {
  actions.fetchClosings();
  actions.fetchProperties();
  ReactDOM.render(
    <Provider store={store}>
      <ClosingsApp/>
    </Provider>,
    container
  )
}
