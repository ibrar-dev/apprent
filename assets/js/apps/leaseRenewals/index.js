import React from 'react';
import ReactDOM from 'react-dom';
import {Provider} from 'react-redux';
import {BrowserRouter} from "react-router-dom";
import LeasesApp from './components';
import store from './store';
import actions from './actions';

const container = document.getElementById('leases-app');

if (container) {
  actions.fetchProperties();
  ReactDOM.render(
    <Provider store={store}>
      <BrowserRouter>
        <LeasesApp/>
      </BrowserRouter>
  </Provider>,
    container);
}