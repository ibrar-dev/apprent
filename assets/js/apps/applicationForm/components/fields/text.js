import React from 'react';
import classset from "classnames";
import {Input} from "reactstrap";

export default (name, value, error, options, label) => {
  return <div className="labeled-box">
  <input className={classset({"form-control": true, 'is-invalid': error})}
                data-private={options.dataPrivate}
                name={name}
                type={options.type}
                value={value}
                autoComplete="new-password"
                onChange={options.component.editField.bind(options.component)}
  />
        <div className="labeled-box-label">{label}</div>
      </div>
}
