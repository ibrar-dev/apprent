import React, {Component} from 'react';
import {connect} from 'react-redux';
import PropertySelect from '../../../components/propertySelect';
import Select from '../../../components/select';
import canEdit from '../../../components/canEdit';
import actions from "../actions";
import Report from './reports';

const reports = {
  rent_roll: 'Rent Roll',
  delinquency: 'Delinquency',
  // availability: 'Availability',
  boxscore: 'BoxScore',
  mtm: 'Month-to-Month',
  move_outs: 'Move Outs',
  collection: 'Collection',
  daily_deposit: 'Daily Deposit',
  aging: 'Aging Report',
  gpr: 'GPR Report',
  expiring_leases: 'Expiring Leases',
  resident_directory: 'Resident Directory'
};

if (canEdit(['Super Admin', 'Regional'])){
  reports.admin_actions = 'Admin Actions'
}

class PropertyReports extends Component {
  state = {loading: false};

  setReport({target: {value}}) {
    this.setState({loading: true});
    actions.setReport(value).finally(() =>
      this.setState({loading: false}))
  }

  render() {
    const {properties, property, report} = this.props;

    if (properties.length === 0) {
      return (
        <p>Loading</p>
      )
    }

    const {loading} = this.state;
    return <>
      <PropertySelect property={property} properties={properties} onChange={actions.setProperty}/>
      {!property && <h4>Please Select a Property Above</h4>}
      {property && <div className="d-flex align-items-center mt-2 mb-2">
        <div className="pl-2">
          Report Type:
        </div>
        <div className="ml-3 w-25">
          <Select options={Object.keys(reports).map(r => {
            return {label: reports[r], value: r};
          })} onChange={this.setReport.bind(this)} value={report} disabled={loading}/>
        </div>
      </div>}
      <Report/>
    </>
  }
}

export default connect(({properties, property, report}) => {
  return {properties, property, report}
})(PropertyReports)
