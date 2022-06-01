import React from 'react';
import { Input } from 'reactstrap';

class LabeledInput extends React.Component {
  render() {
    return (
      <div>
        <label className="apprent-form-control">{this.props.label}</label>
        <Input value={this.props.value}
               className="apprent-form-control"
               onChange={this.props.onChange}/>
      </div>
    )
  }
}

export default LabeledInput;