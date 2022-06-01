import React from 'react';
import {Modal, ModalBody, ModalFooter, ModalHeader, Button, Input, Row, Col} from "reactstrap";
import states from '../../../data/usStates';

class NewProperty extends React.Component {
  state = {address: {}, logo: {}};

  change({target}) {
    this.setState({...this.state, [target.name]: target.value});
  }

  changeAddress({target}) {
    this.setState({...this.state, address: {...this.state.address, [target.name]: target.value}});
  }

  changeLogo({target}) {
    this.setState({...this.state, logo: target.files[0]});
  }

  create() {
    const {name, code, address, logo} = this.state;
    const formData = new FormData();
    formData.append('property[name]', name);
    formData.append('property[code]', code);
    Object.keys(address).forEach(field => formData.append(`property[address][${field}]`, address[field]));
    if (Object.keys(logo).length) formData.append('property[logo]', logo);
    this.props.accept(formData);
  }

  render() {
    const {dismiss} = this.props;
    const {name, code, address: {street, city, state, zip}} = this.state;
    return <Modal toggle={dismiss} isOpen={true} size="lg">
      <ModalHeader toggle={dismiss}>
        Add New Property
      </ModalHeader>
      <ModalBody>
        <Row className="mb-3 align-items-center">
          <Col sm={2}>
            Name
          </Col>
          <Col sm={10}>
            <Input name="name" value={name || ''} onChange={this.change.bind(this)}/>
          </Col>
        </Row>
        <Row className="mb-3 align-items-center">
          <Col sm={2}>
            Code
          </Col>
          <Col sm={10}>
            <Input name="code" value={code || ''} onChange={this.change.bind(this)}/>
          </Col>
        </Row>
        <Row className="mb-3 align-items-center">
          <Col sm={2}>
            Address
          </Col>
          <Col sm={10}>
            <Input placeholder="Address" name="street" value={street || ''} onChange={this.changeAddress.bind(this)}/>
          </Col>
        </Row>
        <Row className="mb-3 align-items-center">
          <Col sm={2}/>
          <Col sm={4}>
            <Input placeholder="City" name="city" value={city || ''} onChange={this.changeAddress.bind(this)}/>
          </Col>
          <Col sm={4}>
            <Input type="select" name="state" value={state || ''} onChange={this.changeAddress.bind(this)}>
              {states.map(s => {
                return <option key={s.value} value={s.value}>{s.label}</option>
              })}
            </Input>
          </Col>
          <Col sm={2}>
            <Input placeholder="ZIP" name="zip" value={zip || ''} onChange={this.changeAddress.bind(this)}/>
          </Col>
        </Row>
        <Row className="mb-3 align-items-center">
          <Col sm={2}>
            Logo
          </Col>
          <Col sm={10}>
            <Input type="file" name="logo" onChange={this.changeLogo.bind(this)}/>
          </Col>
        </Row>
      </ModalBody>
      <ModalFooter>
        <Button onClick={this.create.bind(this)}>Create</Button>
      </ModalFooter>
    </Modal>
  }
}

export default NewProperty;