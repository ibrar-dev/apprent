import React from 'react';
import ReactDOM from 'react-dom';
import {Provider} from 'react-redux';
import actions from "./actions";
import store from "./store";
import CategoriesApp from './components';

const container = document.getElementById('work-order-categories-app');

if (container) {
  actions.fetchWorkOrderCategories();
  ReactDOM.render(<Provider store={store}>
    <CategoriesApp/>
  </Provider>, container);
}