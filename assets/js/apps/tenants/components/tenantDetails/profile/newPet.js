import React from 'react';
import {Popover, PopoverBody, PopoverHeader, Input, Button, Row, Col} from "reactstrap";
import actions from '../../../actions';

class NewPet extends React.Component {
  state = {};

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  save() {
    const {tenant, toggle} = this.props;
    actions.createPet({...this.state, tenant_id: tenant.id}).then(toggle);
  }

  render() {
    const {open, toggle} = this.props;
    const {name, breed, weight, type} = this.state;
    const change = this.change.bind(this);
    return <Popover placement="bottom" isOpen={open} target="new-pet" toggle={toggle}>
      <PopoverHeader>New Pet</PopoverHeader>
      <PopoverBody>
        <Row>
          <Col sm={4} className="d-flex align-items-center">
            <strong>Name</strong>
          </Col>
          <Col sm={8}>
            <Input value={name} name="name" onChange={change}/>
          </Col>
        </Row>
        <Row className="mt-2">
          <Col sm={4} className="d-flex align-items-center">
            <strong>Type</strong>
          </Col>
          <Col sm={8}>
            <Input value={type} name="type" onChange={change}/>
          </Col>
        </Row>
        <Row className="mt-2">
          <Col sm={4} className="d-flex align-items-center">
            <strong>Breed</strong>
          </Col>
          <Col sm={8}>
            <Input value={breed} name="breed" onChange={change}/>
          </Col>
        </Row>
        <Row className="mt-2">
          <Col sm={4} className="d-flex align-items-center">
            <strong>Weight(lb)</strong>
          </Col>
          <Col sm={8}>
            <Input value={weight} type="number" name="weight" onChange={change}/>
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

export default NewPet;