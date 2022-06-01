import React from 'react';
import ReactDom from 'react-dom';
import { ToastContainer, toast } from 'react-toastify';

const mapping = {success: 'success', error: 'danger', warn: 'warning', info: 'info'};

const snackbar = options => {
  ReactDom.render(<ToastContainer autoClose={6000} />, document.getElementById('snackbar-container'));
  const type = mapping[options.args.type];
  type ? toast[options.args.type](options.message, {className: `alert-${type}`}) : toast(options.message);
};

export default snackbar;