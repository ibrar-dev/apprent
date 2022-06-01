import React, {Component} from "react";
import {Button, Modal, ModalBody, ModalFooter, ModalHeader} from "reactstrap";

class AppModal extends Component {
  render() {
    return <Modal isOpen={true} toggle={this.props.close}>
      <ModalHeader toggle={this.props.close}>
        {this.props.heading}
      </ModalHeader>
      <ModalBody>
        <p>Your application has been submitted successfully.</p>
        <p>A leasing agent will be in contact with you within 1 business day.</p>
      </ModalBody>
      <ModalFooter>
        <Button color="primary" onClick={this.props.close}>Thanks!</Button>
      </ModalFooter>
    </Modal>
  }
}

export default AppModal;
