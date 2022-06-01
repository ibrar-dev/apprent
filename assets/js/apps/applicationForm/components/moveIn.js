import React from 'react';
import {connect} from 'react-redux';
import actions from '../actions';
import utils from './utils';
import localization from '../../../components/localization';

class MoveIn extends React.Component {
  state = {}

  editField(e) {
    actions.setApplicationField('move_in', e.target.name, e.target.value);
  }

  render() {
    const userField = utils.userField.bind(this, this.props.application.move_in);
    const {availableUnits, language, floorPlans} = this.props;
    // const unitOptions = availableUnits.map(u => { return {label: u.number, value: u.id}; });
    // unitOptions.sort((a, b) => a.label > b.label ? 1 : -1);
    const floorPlanOptions = floorPlans && floorPlans.length > 0 ? floorPlans.map(fp => {return {label: fp.name, value: fp.id}}) : [];
    return <div className="card">
      <div className="card-header">
        {language.mii}
      </div>
      <div className="card-body pt-0">
        {userField('expected_move_in', language.emi, 'date', {openTo: 0, min: '0', max: 2})}
        {floorPlanOptions.length > 0 && userField('floor_plan_id', 'Floor Plan Type', 'select', {options: floorPlanOptions})}
        <p className="card-text p-2 mt-1">
          Pricing and availability is subject to change at any time.
          Selecting a particular floorplan does not guarantee that floorplans availability.
          If a floorplan is not available for your desired move in date, an alternative floorplan may be proposed, or you may be placed on a waitlist.
        </p>
        {/*{userField('unit_id', 'Unit Number', 'select', {options: unitOptions})}*/}
      </div>
    </div>
  }
}

export default connect((state) => {
  return {application: state.application, availableUnits: state.availableUnits, language: state.language, floorPlans: state.property.floor_plans};
})(MoveIn);
