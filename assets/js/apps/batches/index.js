import React from 'react';
import ReactDOM from 'react-dom';
import {Provider} from 'react-redux';
import store from './store';
import actions from './actions';
import BatchesApp from "./components";

const container = document.getElementById('batches-app');

if (container) {
  actions.fetchProperties();
  actions.fetchAccounts();
  ReactDOM.render(<Provider store={store}>
    <BatchesApp/>
  </Provider>, container);
}