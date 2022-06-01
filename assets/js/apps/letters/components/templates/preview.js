import React from 'react';
import {Modal, ModalHeader, ModalBody} from 'reactstrap';

class Preview extends React.Component {
  state = {};

  render() {
    const {template, toggle, data} = this.props;
    return <Modal size="lg" isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>{template.name}</ModalHeader>
      <ModalBody>
        <iframe src={`data:application/pdf;base64,${data}`} height={550} width="100%"/>
      </ModalBody>
    </Modal>;
  }
}

export default Preview;