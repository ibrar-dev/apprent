import React from 'react';
import StateSelect from './stateSelect';

export default (name, value, error, {component}, label) => {
  return <div className="labeled-box">
  <StateSelect value={value}
                      name={name}
                      error={error}
                      onChange={component.editField.bind(component)}/>
    <div className="labeled-box-label">{label}</div>
  </div>
};