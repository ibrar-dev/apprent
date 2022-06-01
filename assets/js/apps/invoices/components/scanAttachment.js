import React from 'react';
import {Modal, ModalHeader, ModalBody} from 'reactstrap';
import Scanner from '../../../components/scanner';

class ScanAttachment extends React.Component {
  render() {
    const {toggle} = this.props;
    return <Modal isOpen={true} toggle={toggle} size="lg">
      <ModalHeader toggle={toggle}>Scan Invoice Attachment</ModalHeader>
      <ModalBody>
        <Scanner autoStart onScan={this.takeScan.bind(this)}/>
      </ModalBody>
    </Modal>
  }
}

export default ScanAttachment;