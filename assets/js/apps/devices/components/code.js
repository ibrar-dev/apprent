import React from 'react';
import {Modal, ModalHeader, ModalBody} from 'reactstrap';
import QRCode from 'qrcode.react';

class Code extends React.Component {
  render() {
    const {device, toggle} = this.props;
    const data = JSON.stringify(device);
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        {device.name}
      </ModalHeader>
      <ModalBody className="text-center">
        <QRCode value={data} size={320}/>
      </ModalBody>
    </Modal>
  }
}

export default Code;