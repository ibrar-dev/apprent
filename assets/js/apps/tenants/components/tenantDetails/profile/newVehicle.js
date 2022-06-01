import React from 'react';
import {Popover, PopoverBody, PopoverHeader, Input, Button, Row, Col} from "reactstrap";
import actions from '../../../actions';
import Select from '../../../../../components/select';

class NewVehicle extends React.Component {
  state = {};

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  save() {
    const {tenant, toggle} = this.props;
    actions.createVehicle({...this.state, tenant_id: tenant.id}).then(toggle);
  }

  render() {
    const {open, toggle} = this.props;
    const {make_model, color, license_plate, state} = this.state;
    const change = this.change.bind(this);
    return <Popover placement="bottom" isOpen={open} target="new-vehicle" toggle={toggle}>
      <PopoverHeader>New Vehicle</PopoverHeader>
      <PopoverBody>
        <Row>
          <Col sm={4} className="d-flex align-items-center">
            <strong>Make/Model</strong>
          </Col>
          <Col sm={8}>
            <Input value={make_model} name="make_model" onChange={change}/>
          </Col>
        </Row>
        <Row className="mt-2">
          <Col sm={4} className="d-flex align-items-center">
            <strong>Color</strong>
          </Col>
          <Col sm={8}>
            <Input value={color} name="color" onChange={change}/>
          </Col>
        </Row>
        <Row className="mt-2">
          <Col sm={4} className="d-flex align-items-center">
            <strong>LP Number</strong>
          </Col>
          <Col sm={8}>
            <Input value={license_plate} name="license_plate" onChange={change}/>
          </Col>
        </Row>
        <Row className="mt-2">
          <Col sm={4} className="d-flex align-items-center">
            <strong>State</strong>
          </Col>
          <Col sm={8}>
            <Select value={state || ''}
                    onChange={change}
                    options={USSTATES}
                    name="state"/>
          </Col>
        </Row>
        <Row className="mt-2">
          <Col>
            <Button block color="success" onClick={this.save.bind(this)}>
              Save
            </Button>
          </Col>
        </Row>
      </PopoverBody>
    </Popover>;
  }
}

export default NewVehicle;