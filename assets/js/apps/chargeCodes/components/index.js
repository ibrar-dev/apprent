import React from 'react';
import {connect} from 'react-redux';
import Pagination from "../../../components/pagination";
import ChargeCode from './chargeCode';

const headers = [
  {label: 'Code', min: true},
  {label: 'Name', min: true},
  {label: 'Account Number'},
  {label: 'Account'},
  {label: '', min: true}
];

class ChargeCodesApp extends React.Component {
  render() {
    const {chargeCodes} = this.props;
    return <Pagination collection={chargeCodes}
                       component={ChargeCode}
                       headers={headers}
                       title="Charge Codes"
                       field="chargeCode"
    />
  }
}

export default connect(({chargeCodes}) => {
  return {chargeCodes}
})(ChargeCodesApp)