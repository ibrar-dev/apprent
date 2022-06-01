import React from "react";
import {connect} from 'react-redux';
import {withRouter} from "react-router-dom";
import {Card, CardBody, CardHeader, Button} from 'reactstrap';
import UnitSpecs from './unitSpecs';
import actions from "../actions";
import NewUnit from './newUnit';
import Leases from './leases';

class UnitDetails extends React.Component {
  constructor(props) {
    super(props);
    this.state = {tab: 'lease'};
    this.key = 1;
    const unitId = parseInt(props.match.params.id);
    if (!props.unit || props.unit.id !== unitId) actions.fetchUnit(unitId);
  }

  componentDidUpdate(prevProps) {
    if (this.props.match.params.id !== prevProps.match.params.id) {
      const unitId = parseInt(this.props.match.params.id);
      this.key += 1;
      actions.fetchUnit(unitId);
    }
  }

  newUnit() {
    this.setState({newUnit: !this.state.newUnit});
  }

  togglePopover() {
    this.setState({popoverOpen: !this.state.popoverOpen});
  }

  render() {
    const {features, floorPlans, properties, unit, history} = this.props;
    const {newUnit, popoverOpen} = this.state;
    if (!unit) return <div/>;
    const property = properties.filter(p => p.id === unit.property_id)[0];
    if (!property) return <div/>;
    const leases = new Leases(this.props);
    return <div>
      <Button className="m-2" outline color="info" size="sm"
              onClick={() => history.push('/units')}><i className="fas fa-arrow-circle-left"/> Back To Units</Button>
      <Card className="h-100 border-left-0 rounded-0">
        <CardHeader className="d-flex justify-content-between align-items-center" style={{height: 60}}>
          <div className="d-flex align-items-center">
            <div>{property.name} Unit {unit.number}</div>
            <div className="ml-4">
              {leases.dropdown(unit.leases, this.togglePopover.bind(this), 'Popover-' + unit.id, popoverOpen)}
            </div>
          </div>
          <Button className="m-0" color="success" onClick={this.newUnit.bind(this)}>New Unit</Button>
        </CardHeader>
        <CardBody>
          <UnitSpecs property={property} unit={unit}
                     floorPlans={floorPlans.filter(f => f.property_id === property.id)}
                     features={features.filter(ut => ut.property_id === property.id)}/>
        </CardBody>
      </Card>
      {newUnit && <NewUnit toggle={this.newUnit.bind(this)} property={property}/>}
    </div>;
  }
}

export default withRouter(connect(({floorPlans, features, unit, properties, property}) => {
  return {floorPlans, features, unit, properties, property: property || {}};
})(UnitDetails));
