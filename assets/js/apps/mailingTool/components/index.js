import React, {Component} from 'react';
import {connect} from 'react-redux';
import Recipients from './recipients';
import Body from './body';

class MailingApp extends Component {
  state = {};

  render() {
    return <div>
        <Recipients />
        <Body />
    </div>
  }
}

export default connect(({}) => {
  return {}
})(MailingApp)