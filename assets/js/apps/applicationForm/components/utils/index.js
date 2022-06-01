import React from 'react';
import classset from 'classnames';
import fields from '../fields';
import store from '../../store';

const utils = {
  input(type, name, value, error, options, label, index = null) {
    return fields[type](name, value, error, {...options, type, component: this},label, index);
  },
  userField(model, name, label, type = 'text', options = {}, index = null) {
    const error = model.errors[name];
    const lang = store.getState().language;
    return <div>
        {utils.input.call(this, type, name, model[name], error, options,label, index)}
        {typeof error === 'string' && <em className="error invalid-feedback">{lang[error]}</em>}
    </div>;
  }
};

export default utils;
