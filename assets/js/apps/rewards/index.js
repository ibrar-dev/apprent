import React from "react"
import {Provider} from "react-redux"
import RewardsApp from "./components"
import ReactDOM from "react-dom"
import store from "./store"
import actions from './actions';
const container = document.getElementById("rewards-app");

if (container){
  actions.fetchTypes();
  actions.fetchPrizes();
  ReactDOM.render(
    <Provider store={store}>
      <RewardsApp/>
    </Provider>,
    container
  )
}