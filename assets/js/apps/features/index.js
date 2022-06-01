import React from "react"
import {Provider} from "react-redux"
import FeaturesApp from "./components"
import ReactDOM from "react-dom"
import store from "./store";
import actions from './actions';


if (document.getElementById("features-app")) {
  actions.fetchFeatures();
  actions.fetchFloorPlans();
  actions.fetchProperties();
  actions.fetchUnits();
  actions.fetchChargeCodes();
  ReactDOM.render(
    <Provider store={store}>
      <FeaturesApp/>
    </Provider>,
    document.getElementById("features-app")
  )
}
