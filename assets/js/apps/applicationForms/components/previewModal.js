import React from 'react';
import {Modal, ModalHeader, ModalBody} from 'reactstrap';

class PreviewModal extends React.Component {
  state = {};

  render() {
    const {preview, toggle} = this.props;
    return <Modal size="lg" isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>Rental Verification Form</ModalHeader>
      <ModalBody>
        <iframe src={`data:application/pdf;base64,${preview}`} height={550} width="100%"/>
      </ModalBody>
    </Modal>;
  }
}

export default PreviewModal;