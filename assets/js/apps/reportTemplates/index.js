import React from 'react';
import ReactDOM from 'react-dom';
import {Provider} from 'react-redux';
import TemplatesApp from './components';
import store from './store';
import actions from './actions';

const container = document.getElementById('report-templates-app');

if (container) {
  actions.fetchTemplates();
  actions.fetchAccounts();
  ReactDOM.render(<Provider store={store}>
    <TemplatesApp/>
  </Provider>, container);
}