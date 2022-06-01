import React from 'react';
import { Input } from 'reactstrap';

class LabeledSelect extends React.Component {
  render() {
    return (
      <div>
        <label className="apprent-form-control">{this.props.label}</label>
        <Input value={this.props.value}
               type="select"
               className="apprent-form-control"
               onChange={this.props.onChange}
        >
          <option />
          {this.props.options.map((option, index) => {
            return <option key={index} value={option.value}>{option.label}</option>
          })}
        </Input>
      </div>
    )
  }
}

export default LabeledSelect;