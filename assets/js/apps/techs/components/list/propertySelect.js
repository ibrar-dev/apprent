import React from 'react';
import { Label, Input } from 'reactstrap';

const PropertySelect = props => {
    return (
        <div>
            <Label check>
                <input type="checkbox"
                       onChange={props.checked.bind(this, props.property.id)}
                       checked={props.property_ids.includes(props.property.id) ? 'true' : ''} />{' '}
                {props.property.name}
            </Label>
        </div>
    )
};

export default PropertySelect;