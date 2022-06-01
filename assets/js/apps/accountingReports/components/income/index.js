import React from 'react';
import Report from '../report';

class IncomeReport extends React.Component {
  render() {
    return <Report {...this.props} balance={false}/>
  }
}

export default IncomeReport;