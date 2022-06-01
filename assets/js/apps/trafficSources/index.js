import React from "react"
import {Provider} from "react-redux"
import TrafficSourcesApp from "./components"
import ReactDOM from "react-dom"
import store from "./store"
import actions from './actions';

const container = document.getElementById("traffic-sources-app");

if (container) {
  actions.fetchTrafficSources();
  ReactDOM.render(
		<Provider store={store}>
			<TrafficSourcesApp/>
		</Provider>,
    container
	)
}