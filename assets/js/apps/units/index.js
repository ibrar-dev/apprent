import React from "react"
import {Provider} from "react-redux"
import {BrowserRouter} from 'react-router-dom'
import UnitsApp from "./components"
import ReactDOM from "react-dom"
import store from "./store";
import actions from './actions';


if (document.getElementById("units-app")) {
  actions.fetchUnits();
  actions.fetchProperties();
  actions.fetchFeatures();
  actions.fetchFloorPlans();
  ReactDOM.render(
    <Provider store={store}>
      <BrowserRouter>
        <UnitsApp/>
      </BrowserRouter>
    </Provider>,
    document.getElementById("units-app")
  )
}
