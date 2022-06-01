import React from 'react';
import classset from "classnames";
import MaskedInput from 'react-text-mask'

const masks = {
  phoneNumber: ['(', /[1-9]/, /\d/, /\d/, ')', ' ', /\d/, /\d/, /\d/, '-', /\d/, /\d/, /\d/, /\d/]
};

export default (name, value, error, options, label) => {
  return <div className="labeled-box">
  <MaskedInput className={classset({"form-control": true, 'is-invalid': error})}
                      name={name}
                      type={options.type}
                      value={value}
                      mask={masks.phoneNumber}
                      onChange={options.component.editField.bind(options.component)}

  />
    <div className="labeled-box-label">{label}</div>
  </div>
};