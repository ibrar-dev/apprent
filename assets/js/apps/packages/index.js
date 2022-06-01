import React from 'react';
import ReactDOM from 'react-dom';
import {Provider} from 'react-redux';
import store from "./store";
import PackageApp from './components';

const container = document.getElementById('packages-app');

if (container) {
  ReactDOM.render(<Provider store={store}>
  
  <PackageApp></PackageApp>
  </Provider>, container);
}