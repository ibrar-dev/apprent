import React from 'react';
import ReactDOM from 'react-dom';
import {Provider} from 'react-redux';
import {BrowserRouter} from "react-router-dom";
import LettersApp from './components';
import store from './store';
import actions from './actions';

const container = document.getElementById('letter-app');

if (container) {
  actions.fetchProperties();
  ReactDOM.render(
    <Provider store={store}>
      <BrowserRouter>
        <LettersApp />
      </BrowserRouter>
    </Provider>,
    container);
}