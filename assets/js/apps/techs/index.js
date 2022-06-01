import React from "react"
import {Provider} from "react-redux"
import {BrowserRouter} from 'react-router-dom'
import TechsApp from "./components"
import ReactDOM from "react-dom"
import store from "./store"
import actions from './actions';

if (document.getElementById("techs-app")) {
  actions.initialLoad();
  ReactDOM.render(
		<Provider store={store}>
      <BrowserRouter>
			  <TechsApp/>
      </BrowserRouter>
		</Provider>,
		document.getElementById("techs-app")
	)
}