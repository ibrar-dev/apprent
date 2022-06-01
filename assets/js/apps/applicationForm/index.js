import React from 'react';
import ReactDOM from 'react-dom';
import actions from './actions';
import ApplicationForm from './components';

const container = document.getElementById('application-form');

actions.setProperty(container.dataset.property);

if (container) {
  actions.fetchProperty();
  ReactDOM.render(
    <ApplicationForm />,
    container
  );
}
