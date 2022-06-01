import React from 'react';
import ReactDOM from 'react-dom';
import {Provider} from 'react-redux';
import ChargeCodesApp from './components';
import store from './store';
import actions from './actions';

const container = document.getElementById('charge-codes-app');

if (container) {
  actions.fetchChargeCodes();
  ReactDOM.render(<Provider store={store}>
    <ChargeCodesApp/>
  </Provider>, container);
}