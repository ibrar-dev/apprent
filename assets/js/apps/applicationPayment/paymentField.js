import React from 'react';
import classNames from 'classnames';
import MaskedInput from 'react-text-mask'
import Payment from "payment";

function clearNumber(value = '') {
  return value.replace(/\D+/g, '');
}

function formatCreditCardNumber(value) {
  if (!value) {
    return value;
  }

  const issuer = Payment.fns.cardType(value);
  const clearValue = clearNumber(value);
  let nextValue;

  switch (issuer) {
    case 'amex':
      nextValue = `${clearValue.slice(0, 4)} ${clearValue.slice(
        4,
        10,
      )} ${clearValue.slice(10, 15)}`;
      break;
    case 'dinersclub':
      nextValue = `${clearValue.slice(0, 4)} ${clearValue.slice(
        4,
        10,
      )} ${clearValue.slice(10, 14)}`;
      break;
    default:
      nextValue = `${clearValue.slice(0, 4)} ${clearValue.slice(
        4,
        8,
      )} ${clearValue.slice(8, 12)} ${clearValue.slice(12, 19)}`;
      break;
  }

  return nextValue.trim();
}

const types = {
  number(value, onChange, focus, error) {
    const change = (e) => {
      const value = formatCreditCardNumber(e.target.value);
      onChange({target: {name: e.target.name, value}});
    };

    return <input className={classNames({"form-control": true, "is-invalid": error})}
                  name="number"
                  pattern="[\d| ]{16,22}"
                  value={value}
                  onFocus={focus}
                  onChange={change}

    />;
  },
  expiry(value, onChange, focus, error) {
    return <MaskedInput className={classNames({"form-control": true, "is-invalid": error})}
                        name="expiry"
                        value={value}
                        onFocus={focus}
                        mask={[/[01]/, /\d/, '/', /\d/, /\d/]}
                        onChange={onChange}
    />;
  },
  cvc(value, onChange, focus, error) {
    return <input type="number"
                  className={classNames({"form-control": true, "is-invalid": error})}
                  name="cvc"
                  onChange={onChange}
                  value={value}
                  onFocus={focus}
                  autoComplete="new-password"/>
  },
  name(value, onChange, focus, error) {
    return <input type="text"
                  className={classNames({"form-control": true, "is-invalid": error})}
                  name="name"
                  onChange={onChange}
                  value={value}
                  onFocus={focus}
                  autoComplete="new-password"/>
  }
};


export default (value, type, label, onChange, focus, error) => {
  return <div className="row margin-row">
    <div className="col-lg-3">
      <div className="middle-align form-control-label">
        <label htmlFor={type}>{label}</label>
      </div>
    </div>
    <div className="col-lg-9">
      {types[type](value, onChange, focus, error)}
    </div>
  </div>
};