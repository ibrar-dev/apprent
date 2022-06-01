import React from 'react';
import classset from "classnames";

export default (name, value, error, options, label) => {
  return <div className="labeled-box">
    <select className={classset({"form-control": true, 'is-invalid': error})}
            name={name}
            value={value}
            onChange={options.component.editField.bind(options.component)}>
      <option value="">Choose One</option>
      {options.options.map((o, i) => <option key={i} value={o.match ? o : o.value}>
        {o.match ? o : o.label}
      </option>)}
    </select>
    <div className="labeled-box-label">{label}</div>
  </div>
};