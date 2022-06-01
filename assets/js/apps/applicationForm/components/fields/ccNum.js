import React from 'react';
import classset from 'classnames';
import Payment from 'payment';
import {Input} from "reactstrap";

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

export default (name, value, error, options, label) => {
  const change = (e) => {
    const value = formatCreditCardNumber(e.target.value);
    options.component.editField.call(options.component, {target: {name: e.target.name, value}});
  };

  return <div className="labeled-box">
    <Input
      data-private
      invalid={!!error}
      value={value || ''}
      name={name}
      pattern="[\d| ]{16,22}"
      type={options.type}
      onChange={change}
      data-private
    />
    <div className="labeled-box-label">{label}</div>
  </div>
};
