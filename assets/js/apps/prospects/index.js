import React from "react"
import {Provider} from "react-redux"
import ProspectsApp from "./components"
import ReactDOM from "react-dom"
import store from "./store"
import actions from './actions';

const container = document.getElementById("prospects-app");

if (container) {
  actions.fetchProspects();
  actions.fetchProperties().then(() => {
  	actions.setProperty(store.getState().properties[0]);
	});
  actions.fetchTrafficSources();
  actions.fetchShowings();
  actions.fetchOpenings();
  ReactDOM.render(
		<Provider store={store}>
			<ProspectsApp/>
		</Provider>,
    container
	)
}