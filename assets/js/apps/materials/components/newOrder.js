import React from 'react';
import {Modal, ModalHeader, ModalBody, Table, Collapse, ModalFooter, Button} from 'reactstrap';
import actions from '../actions';
import {ValidatedInput} from '../../../components/validationFields';
import {connect} from "react-redux";

class NewOrder extends React.Component {
  state = {
    newQuantity: '',
    quantities: []
  };

  updateQuantity(m, e) {
    const {materials} = this.props;
    let material = materials.find(mat => {
      return mat.id === m.id
    });
    material.quantity = parseInt(e.target.value);
    materials[materials.indexOf(material)] = material;
    this.setState({...this.state, materials: materials})
  }

  removeFromMaterials(m) {
    actions.addToMaterialCart(m, 'REMOVE');
    this.forceUpdate();
  }

  render() {
    const {close, materials} = this.props;
    const {newQuantity} = this.state;
    return <Modal isOpen={true} size="lg">
      <ModalHeader toggle={close}>
        Record Order
      </ModalHeader>
      <ModalBody>
        <Table striped bordered>
          <tbody>
            {materials.length >= 1 && materials.map(m => {
              return <tr className="d-flex" key={m.id}>
                <td className="flex-grow-1">{m.name}</td>
                <td className="flex-shrink-1">
                  <ValidatedInput context={this}
                                  validation={(v) => v >= 1}
                                  feedback="Quantity is required"
                                  type="number"
                                  name="quantity"
                                  onChange={this.updateQuantity.bind(this, m)}
                                  value={newQuantity} />
                </td>
                <td className="nowrap align-middle btn-outline-warning flex-shrink-1" onClick={this.removeFromMaterials.bind(this, m)}>Remove</td>
              </tr>
            })}
          </tbody>
        </Table>
      </ModalBody>
      <Collapse isOpen={materials.length >= 1}>
        <ModalFooter>
          <Button outline color="success">Submit Order</Button>
        </ModalFooter>
      </Collapse>
    </Modal>
  }
}

export default connect(({materialCart}) => {
  return {materials: materialCart}
})(NewOrder);