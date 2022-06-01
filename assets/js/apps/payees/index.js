import React from 'react';
import ReactDOM from 'react-dom';
import {BrowserRouter} from "react-router-dom";
import {Provider} from 'react-redux';
import PayeesApp from './components';
import store from './store';
import actions from './actions';

const container = document.getElementById('payees-app');

if (container) {
  actions.fetchPayees();
  ReactDOM.render(<Provider store={store}>
    <BrowserRouter>
      <PayeesApp/>
    </BrowserRouter>
  </Provider>, container);
}