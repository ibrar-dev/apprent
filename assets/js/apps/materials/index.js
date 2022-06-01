import React from "react"
import {Provider} from "react-redux"
import {BrowserRouter} from 'react-router-dom'
import MaterialsApp from "./components"
import ReactDOM from "react-dom"
import store from "./store"
import actions from './actions';

if (document.getElementById("materials-app")) {
  actions.fetchStocks();
  actions.fetchMaterialTypes();
  ReactDOM.render(
    <Provider store={store}>
      <BrowserRouter>
        <MaterialsApp/>
      </BrowserRouter>
    </Provider>,
    document.getElementById("materials-app")
  )
}
