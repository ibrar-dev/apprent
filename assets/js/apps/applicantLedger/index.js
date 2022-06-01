import React from "react";
import {Provider} from "react-redux";
import {BrowserRouter} from 'react-router-dom';
import Applicants from "./components";
import ReactDOM from "react-dom";
import store from "./store";

const container = document.getElementById("applicant-ledger");
if (container) {
  ReactDOM.render(
    <Provider store={store}>
      <BrowserRouter>
        <Applicants/>
      </BrowserRouter>
    </Provider>,
    container
  )
}