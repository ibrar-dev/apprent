import React from 'react';
import ReactDOM from 'react-dom';
import {BrowserRouter} from "react-router-dom";
import Permissions from './components';
import actions from './actions';
import store from "./store";
import {Provider} from "react-redux";

const container = document.getElementById('org-chart-app');

if (container) {
  ReactDOM.render(
    <Provider store={store}>
      <BrowserRouter>
        <Permissions/>
      </BrowserRouter>
    </Provider>,
    container);
}
