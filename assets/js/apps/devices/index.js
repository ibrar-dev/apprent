import React from 'react';
import {Provider} from 'react-redux';
import DevicesApp from './components';
import ReactDOM from 'react-dom';
import store from './store';
import actions from './actions';

const container = document.getElementById('devices-app');

if (container) {
  actions.fetchProperties();
  actions.fetchDevices();
  ReactDOM.render(
    <Provider store={store}>
      <DevicesApp/>
    </Provider>,
    container
  )
}
