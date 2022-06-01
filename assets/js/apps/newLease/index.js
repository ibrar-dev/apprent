import React from 'react';
import ReactDOM from 'react-dom';
import {Provider} from 'react-redux';
import NewLease from './components';
import store from './store';
import actions from './actions';

const container = document.getElementById('new-lease-app');

if (container) {
  actions.fetchLeaseParams();
  ReactDOM.render(<Provider store={store}>
    <NewLease/>
  </Provider>, container);
}