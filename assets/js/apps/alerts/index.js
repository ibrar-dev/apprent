import React from 'react';
import ReactDOM from 'react-dom';
import {Provider} from 'react-redux';
import AlertsApp from './components';
import store from './store';
import actions from './actions';

const container = document.getElementById('alerts-app');

if (container) {
  actions.initializeChannel();
  ReactDOM.render(<Provider store={store}>
    <AlertsApp/>
  </Provider>, container);
}
