import React from 'react';
import {Modal, ModalHeader, ModalBody, Row, Col} from 'reactstrap';
import Types from './types';
import actions from '../actions';

class NewMaterial extends React.Component {
  state = {name: '', cost: 1, inventory: 1, desired: 1, ref_number: ''};

  change(e) {
    this.setState({...this.state, [e.target.name]: e.target.value});
  }

  create() {
    actions.createMaterial(this.props.stock.id, this.state).then(this.props.close);
  }

  render() {
    const {name, cost, inventory, desired, ref_number} = this.state;
    const {close} = this.props;
    return <Modal isOpen={true}>
      <ModalHeader toggle={close}>
        Create New Material
      </ModalHeader>
      <ModalBody>
        <Row className="mb-2">
          <Col sm={3}>
            Type
          </Col>
          <Col sm={9}>
            <Types onSelect={this.change.bind(this)} />
          </Col>
        </Row>
        <Row className="mb-2">
          <Col sm={3}>
            Name
          </Col>
          <Col sm={9}>
            <input className="form-control" name="name" value={name} onChange={this.change.bind(this)}/>
          </Col>
        </Row>
        <Row className="mb-2">
          <Col sm={3}>
            Ref Number
          </Col>
          <Col sm={9}>
            <input className="form-control" name="ref_number" value={ref_number} onChange={this.change.bind(this)}/>
          </Col>
        </Row>
        <Row className="mb-2">
          <Col sm={3}>
            Cost
          </Col>
          <Col sm={9}>
            <input type="number" className="form-control" name="cost" value={cost} onChange={this.change.bind(this)}/>
          </Col>
        </Row>
        <Row className="mb-2">
          <Col sm={3}>
            Current Inventory
          </Col>
          <Col sm={9}>
            <input type="number" className="form-control" name="inventory" value={inventory}
                   onChange={this.change.bind(this)}/>
          </Col>
        </Row>
        <Row className="mb-2">
          <Col sm={3}>
            Desired Inventory
          </Col>
          <Col sm={9}>
            <input type="number" className="form-control" name="desired" value={desired}
                   onChange={this.change.bind(this)}/>
          </Col>
        </Row>
        <Row className="mb-2">
          <Col sm={3}/>
          <Col sm={9}>
            <button className="btn btn-success btn-block" onClick={this.create.bind(this)}>
              Create
            </button>
          </Col>
        </Row>
      </ModalBody>
    </Modal>
  }
}

export default NewMaterial;