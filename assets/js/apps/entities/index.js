import React from "react"
import {Provider} from "react-redux"
import EntitiesApp from "./components"
import ReactDOM from "react-dom"
import actions from './actions';
import store from "./store"

if (document.getElementById("entities-app")) {
  actions.fetchProperties();
  actions.fetchEntities();
    ReactDOM.render(
      <Provider store={store}>
        <EntitiesApp />
      </Provider>,
      document.getElementById("entities-app")
    )
}
