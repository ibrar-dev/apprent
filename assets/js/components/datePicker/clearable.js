import React from 'react';
import {Button, InputGroup, InputGroupAddon} from 'reactstrap';
import DatePicker from './index';

class Clearable extends React.Component {
  clear() {
    const {name, onChange} = this.props;
    if (name) {
      onChange({target: {value: null, name}})
    } else {
      onChange(null);
    }
  }
  render() {
    const {disabled} = this.props;
    return <InputGroup className="clearable-datepicker">
      <DatePicker {...this.props}/>
      <InputGroupAddon addonType="append">
        <Button onClick={this.clear.bind(this)}
                style={{opacity: 1}}
                color={disabled ? "outline-gray-disabled" : "outline-gray"} disabled={disabled}>
          <i className="fas fa-times"/>
        </Button>
      </InputGroupAddon>
    </InputGroup>
  }
}

export default Clearable;