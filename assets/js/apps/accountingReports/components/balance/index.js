import React from 'react';
import Report from '../report';

class BalanceReport extends React.Component {
  render() {
    return <Report {...this.props} balance={true}/>
  }
}

export default BalanceReport;