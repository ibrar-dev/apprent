import React from "react"
import {Provider} from "react-redux"
import ReactDOM from "react-dom"
import store from "./store"
import actions from './actions';
import MailingApp from './components';


if (document.getElementById("mailing-tool-app")) {
  actions.fetchProperties();
  actions.fetchMailTemplates();
  ReactDOM.render(
    <Provider store={store}>
      <MailingApp/>
    </Provider>,
    document.getElementById("mailing-tool-app")
  )
}