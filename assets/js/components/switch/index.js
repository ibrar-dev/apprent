import React from 'react';
import ReactSwitch from 'react-switch';

class Switch extends React.Component {
  change(value) {
    const {name, onChange} = this.props;
    onChange({target: {name, value}});
  }

  render() {
    return <ReactSwitch {...this.props} onChange={this.change.bind(this)}/>
  }
}

export default Switch;