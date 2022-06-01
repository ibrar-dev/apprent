import React from "react"
import {Provider} from "react-redux"
import ShowingsApp from "./components"
import ReactDOM from "react-dom"
import store from "./store"
import actions from './actions';

const container = document.getElementById("schedule-showing");
if (container) {
  actions.fetchOpenings();
  ReactDOM.render(
    <Provider store={store}>
      <ShowingsApp/>
    </Provider>,
    container
  )
}