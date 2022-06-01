import React from "react";
import {Provider} from "react-redux";
import {BrowserRouter} from 'react-router-dom';
import ApplicationForms from "./components";
import ReactDOM from "react-dom";
import store from "./store";
import actions from './actions';

const container = document.getElementById("application-forms");
if (container) {
  actions.fetchProperties();
  ReactDOM.render(
    <Provider store={store}>
      <BrowserRouter>
        <ApplicationForms/>
      </BrowserRouter>
    </Provider>,
    container
  )
}
