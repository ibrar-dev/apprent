import React from 'react';
import GeneralLedgerMain from './generalLedger';
import GeneralLedgerPrint from './generalLedgerPrint';

class GeneralLedger extends React.Component {
  render() {
    const {result, parent} = this.props;
    return <>
      <GeneralLedgerMain parent={parent} data={result}/>
      <div id="report-data" style={{display: 'none'}}>
        <GeneralLedgerPrint data={result}/>
      </div>
    </>
  }
}

export default GeneralLedger