import React from 'react';
import ReactDOM from 'react-dom';
import {Provider} from 'react-redux';
import ReportsApp from './components';
import store from './store';
import actions from './actions';

const container = document.getElementById('reports-app');

if (container) {
  actions.fetchTemplates();
  actions.fetchProperties();
  ReactDOM.render(<Provider store={store}>
    <ReportsApp/>
  </Provider>, container);
}