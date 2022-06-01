import React from 'react';
import ReactDOM from 'react-dom';
import {Provider} from 'react-redux';
import ResidentsApp from './components';
import store from './store';
import actions from './actions';

const container = document.getElementById('resident-events-app');

if (container) {
  actions.fetchProperties();
  ReactDOM.render(<Provider store={store}>
    <ResidentsApp/>
  </Provider>, container);
}