import React from "react"
import {Provider} from "react-redux"
import TasksApp from "./components"
import ReactDOM from "react-dom"
import store from "./store"

const container = document.getElementById("tasks-app");

if (container) {
  ReactDOM.render(
    <Provider store={store}>
      <TasksApp/>
    </Provider>,
    container
  )
}
