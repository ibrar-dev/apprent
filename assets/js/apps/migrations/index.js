import React from "react"
import {Provider} from "react-redux"
import MigrationsApp from "./components"
import ReactDOM from "react-dom"
import store from "./store"
import actions from './actions';

if (document.getElementById("migrations-app")) {
  actions.fetchMigrations();
  ReactDOM.render(
    <Provider store={store}>
      <MigrationsApp/>
    </Provider>,
    document.getElementById("migrations-app")
  )
}
