import React, {Component} from 'react';
import {Row, Col, InputGroup, InputGroupAddon} from "reactstrap";
import {Modal, ModalHeader, ModalBody, ModalFooter, Alert, Button, Input} from "reactstrap";
import actions from '../../actions';
import PropertySelect from './propertySelect';

class NewTech extends Component {
  state = {
    name: '',
    phone: '',
    email: '',
    type: '',
    selectedPropertyIDs: [],
    invalidAttributes: false,
    responseErrors: {},
  };

  change({target}) {
    this.setState({...this.state, [target.name]: target.value});
  }

  create() {
    const {name, phone, email, type, selectedPropertyIDs} = this.state;
    if (name === '' || phone === '' || email === '' || selectedPropertyIDs === []) {
      this.setState({invalidAttributes: true})
    } else {
      actions.saveNewTech(name, phone, email, type, selectedPropertyIDs)
      .then(actions.fetchTechs())
      .then(this.props.cancel)
      .catch(({response}) => {
        this.setState({
          invalidAttributes: true,
          responseErrors: response.data.errors,
        })
      })
    }
  }

  onDismiss() {
    this.setState({invalidAttributes: false, responseErrors: {}});
  }

  addToPropertyIDs(id) {
    const propertyArray = this.state.selectedPropertyIDs;
    propertyArray.includes(id) ? propertyArray.splice(propertyArray.indexOf(id), 1) : propertyArray.push(id);
    this.setState({selectedPropertyIDs: propertyArray});
  }

  render() {
    const {properties, cancel} = this.props;
    const {name, phone, email, type, invalidAttributes} = this.state;
    const style = {
      border: '1px solid grey',
      borderRadius: '5px',
      maxHeight: '150px',
      overflowY: 'scroll'
    };

    return <Modal isOpen={true} toggle={cancel} size="lg">
      <ModalHeader toggle={cancel}>
        New Tech
      </ModalHeader>
      <ModalBody>
        <Row className="mb-3">
          <Col md={6}>
            <Input placeholder="Tech Name" name="name" value={name} onChange={this.change.bind(this)}/>
          </Col>
          <Col md={6}>
            <Input placeholder="Tech Type" name="type" value={type} onChange={this.change.bind(this)}/>
          </Col>
        </Row>
        <Row>
          <Col md={6}>
            <InputGroup>
              <InputGroupAddon addonType="prepend">
                <span className="fas fa-phone input-group-text d-flex align-items-center"/>
              </InputGroupAddon>
              <Input placeholder="Phone Number" name="phone" value={phone} onChange={this.change.bind(this)}/>
            </InputGroup>
            <br/>
            <InputGroup>
              <InputGroupAddon addonType="prepend">
                <span className="fas fa-envelope input-group-text d-flex align-items-center"/>
              </InputGroupAddon>
              <Input placeholder="Email Address" type="email" name="email" value={email}
                     onChange={this.change.bind(this)}/>
            </InputGroup>
            <br/>
            {invalidAttributes &&
              <Alert color="danger" toggle={this.onDismiss.bind(this)}>
                {
                  Object.keys(this.state.responseErrors).length
                  ? (
                    <>
                      {Object.keys(this.state.responseErrors).map((errorKey) => (<p key={errorKey}>{this.state.responseErrors[errorKey]}</p>))}
                    </>
                  )
                  : (<p>Please make sure all the information is correct</p>)
                }
            </Alert>}
          </Col>
          <Col md={6}>
            <Col md={12} style={style}>
              {properties.map((p, index) => {
                return (<PropertySelect key={index} property={p} checked={this.addToPropertyIDs.bind(this)}
                                        property_ids={this.state.selectedPropertyIDs}/>)
              })}
            </Col>
          </Col>
        </Row>
      </ModalBody>
      <ModalFooter>
        <Button color="info" className="mr-3" onClick={this.create.bind(this)}>
          Save
        </Button>
        <Button color="danger" onClick={this.props.cancel}>
          Cancel
        </Button>
      </ModalFooter>
    </Modal>
  }
}

export default NewTech;