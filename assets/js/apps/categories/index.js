import React from "react"
import {Provider} from "react-redux"
import CategoriesApp from "./components"
import ReactDOM from "react-dom"
import store from "./store"
import actions from './actions';

if (document.getElementById("categories-app")) {
	actions.fetchCategories();
	ReactDOM.render(
			<Provider store={store}>
				<CategoriesApp />
			</Provider>,
			document.getElementById("categories-app")
	)
}