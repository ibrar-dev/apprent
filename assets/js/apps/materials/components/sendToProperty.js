import React, { Component } from 'react';
import {Modal, ModalHeader, ModalBody, Input, ModalFooter, Button} from 'reactstrap';
import {connect} from "react-redux";
import actions from '../actions';
import Select from '../../../components/select';
import snackbar from '../../../components/snackbar';

class SendToProperty extends Component {
  state = {
    quantity: 1,
    selectedProperty: ''
  };

  updateQuantity(e) {
    this.setState({...this.state, quantity: parseInt(e.target.value)});
  }

  selectProperty({target: {value}}) {
    this.setState({...this.state, selectedProperty: value.id, selectedPropertyName: value.name});
  }

  sendMaterials() {
    const {material, stock} = this.props;
    const log = {quantity: this.state.quantity, property_id: this.state.selectedProperty, material_id: material.id, stock_id: stock.id};
    const promise = actions.sendMaterial(log, material);
    promise.then(() => {
      this.props.toggle();
      snackbar({message: `${this.state.quantity} of ${material.name} successfully sent to ${this.state.selectedPropertyName}`, args: {type: 'success'}});
    });
    promise.catch(() => {
      snackbar({message: "Error", args: {type: 'error'}})
    })
  }

  render() {
    const {material, toggle, stock} = this.props;
    const {quantity, selectedProperty} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader>Send <b>{material.name}</b> to Property</ModalHeader>
      <ModalBody>
        <div className='form-group'>
          <label>Quantity</label>
          <Input type="number" placeholder='Quantity' value={quantity} onChange={this.updateQuantity.bind(this)} max={material.inventory} min={1}/>
        </div>
        <div className="form-group">
          <label>Property</label>
          <Select value={selectedProperty}
                  onChange={this.selectProperty.bind(this)}
                  options={stock.properties.map(p => {
                    return {value: {id: p.id, name: p.name}, label: p.name}
                  })} />
        </div>
      </ModalBody>
      <ModalFooter>
        <Button outline color='success' onClick={this.sendMaterials.bind(this)}>Send</Button>
      </ModalFooter>
    </Modal>
  }
}

export default connect(({stock}) => {
  return {stock}
})(SendToProperty);