import React, {Component} from 'react';
import {Button, Modal, ModalHeader, ModalBody, ModalFooter} from 'reactstrap';
import {CSVLink} from 'react-csv';
import {PDFCon} from "./pdfConverter";

const date = (new Date(Date.now()).toLocaleString().split(',')[0]);

class FileExport extends Component {
  render() {
    const {toggle, transactions} = this.props;
    const {pdf, csv} = PDFCon(transactions);
    return <Modal isOpen={true} toggle={toggle} size="lg">
      <ModalHeader toggle={toggle}>Export Options</ModalHeader>
      <ModalBody style={{height: "600px"}}>
        <object data={pdf.output('datauristring')} height="100%" width="100%"/>
      </ModalBody>
      <ModalFooter>
        <CSVLink data={csv} filename={date}><Button color="primary">CSV Download</Button></CSVLink>
        <Button color="primary" onClick={() => pdf.save(date)}>PDF Download</Button>
        <Button color="secondary" onClick={toggle}>Close</Button>
      </ModalFooter>
    </Modal>
  }
}

export default FileExport