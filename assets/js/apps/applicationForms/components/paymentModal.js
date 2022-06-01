import React from 'react';
import {Modal, ModalHeader, ModalBody, ModalFooter} from 'reactstrap';

class PaymentModal extends React.Component {
  state = {};

  render() {
    const {toggle} = this.props;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>Submit Check or Money Order</ModalHeader>
      <ModalBody>
        Create an admin payment through the <a href={`/payments`} target="_blank">deposits interface.</a>
      </ModalBody>
      <ModalFooter>
        <a href={`/payments`} className="btn btn-info" target="_blank">Add Payment</a>
      </ModalFooter>
    </Modal>
  }
}

export default PaymentModal;