import React from 'react';
import ReactDOM from 'react-dom';
import {Provider} from 'react-redux';
import store from './store';
import actions from './actions';
import BudgetsApp from "./components";

const container = document.getElementById('budgets-app');

if (container) {
  actions.fetchProperties();
  ReactDOM.render(<Provider store={store}>
    <BudgetsApp/>
  </Provider>, container);
}