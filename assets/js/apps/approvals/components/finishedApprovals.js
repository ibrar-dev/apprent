import React, {Component} from 'react';
import {connect} from "react-redux";

class FinishedApprovals extends Component {
  state = {}
  render() {
    return <h1>Finished Approvals</h1>
  }
}

export default connect(({approvals}) => {
  return {approvals}
})(FinishedApprovals);