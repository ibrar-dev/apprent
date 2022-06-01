import React from 'react';

const radioChange = (component, e, value) => {
  component.editField.call(
    component,
    {target: {name: e.target.name, value}}
  );
};

export default (name, value, _, {component}, label) => (
  <label className="align-items-center">
    <div className="ml-2">{label}</div>
    <span className="ml-4">
      <label className="align-items-center mr-1">
        {component.props.lang.yes}
      </label>
      <input
        type="radio"
        name={name}
        id={name}
        checked={value}
        value={true}
        onChange={(e) => radioChange(component, e, true)}
      />
    </span>
    <span className="ml-4">
      <label className="align-items-center mr-1">
        No
      </label>
      <input
        type="radio"
        name={name}
        id={name}
        value={false}
        checked={value === false}
        onChange={(e) => radioChange(component, e, false)}
      />
    </span>
  </label>
);
