import React from 'react';
import {connect} from 'react-redux';
import {extract} from '../config';

class FormBody extends React.Component {
  static key(stage) {
    return extract('component')[stage];
  }

  render() {
    return FormBody.key(this.props.stage);
  }
}

export default connect((s) => { return {stage: s.stage} })(FormBody);