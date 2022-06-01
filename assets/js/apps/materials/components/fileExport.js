import React, {Component} from 'react';
import {Button, Modal, ModalHeader, ModalBody, ModalFooter} from 'reactstrap';
import {CSVLink} from 'react-csv';

const date = (new Date(Date.now()).toLocaleString().split(',')[0]);

class FileExport extends Component {
  state = {modal: false};

  pdfDownload() {
    this.props.pdf.save(date);
  }

  render() {
    const {toggle, modal, pdf, csv} = this.props;
    return <Modal isOpen={modal} toggle={toggle} size="lg">
      <ModalHeader toggle={toggle}>Export Options</ModalHeader>
      <ModalBody style={{height: "600px"}}>
        <iframe src={pdf.output('datauristring')} height="100%" width="100%"/>
      </ModalBody>
      <ModalFooter>
        <CSVLink data={csv} filename={date}><Button color="primary">CSV Download</Button></CSVLink>
        <Button color="primary" onClick={this.pdfDownload.bind(this)}>PDF Download</Button>
        <Button color="secondary" onClick={toggle}>Close</Button>
      </ModalFooter>
    </Modal>
  }
}

export default FileExport