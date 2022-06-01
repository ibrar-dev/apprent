import React from 'react';
import {Input} from "reactstrap";

export default (name, value, error, {component}, label) => {
    return <div className="labeled-box">
        <Input className="labeled-box"
                     value={value}
                     name={name}
                     error={error}
                     onBlur={component.formatField.bind(component)}
                     onChange={component.editField.bind(component)}/>
        <div className="labeled-box-label">{label}</div>
    </div>
};