import React from 'react';
import ReactDOM from 'react-dom';
import {Provider} from 'react-redux';
import actions from "./actions";
import store from "./store";
import VendorsApp from './components';

const container = document.getElementById('vendors-app');

if (container) {
 actions.refresh();
  ReactDOM.render(<Provider store={store}>
    <VendorsApp/>
  </Provider>, container);
}