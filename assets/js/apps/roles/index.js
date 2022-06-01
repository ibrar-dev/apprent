import React from "react"
import {Provider} from "react-redux"
import RolesApp from "./components"
import ReactDOM from "react-dom"
import store from "./store"
import actions from './actions';

const container = document.getElementById("roles-app");
if (container) {
  actions.fetchRoles();
  actions.fetchRoleTree();
  ReactDOM.render(
    <Provider store={store}>
      <RolesApp/>
    </Provider>,
    container
  )
}