import React from 'react';
import ReactDOM from 'react-dom';
import {Provider} from 'react-redux';
import AccountsApp from './components';
import store from './store';
import actions from './actions';

const container = document.getElementById('accounts-app');

if (container) {
  actions.fetchCategories();
  actions.fetchProperties();
  ReactDOM.render(<Provider store={store}>
    <AccountsApp/>
  </Provider>, container);
}