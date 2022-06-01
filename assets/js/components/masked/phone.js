import React from 'react';
import classset from "classnames";
import MaskedInput from 'react-text-mask'

const mask = ['(', /[1-9]/, /\d/, /\d/, ')', ' ', /\d/, /\d/, /\d/, '-', /\d/, /\d/, /\d/, /\d/];

export default class extends React.Component {
  render() {
    const {error, name, onChange, value, disabled, className} = this.props;
    return <MaskedInput className={classset({"form-control": true, 'is-invalid': error, [className || '']: true})}
                        name={name}
                        disabled={disabled}
                        value={value}
                        mask={mask}
                        onChange={onChange}/>;
  }
}