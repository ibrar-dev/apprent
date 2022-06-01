import React, {Component} from 'react';
import {Button, Modal, ModalHeader, ModalBody, ModalFooter} from 'reactstrap';
import {CSVLink} from 'react-csv';
import JsPDF from 'jspdf';
import 'jspdf-autotable';
import moment from "moment";
import {toCurr} from '../../../utils';

function PDFCon({payment, admin_payment}) {
  const columns = ["Date", "Account", "Charge", "Payment", "Balance"];
  const headerString = "Ledger";
  const rows = [
    [
      moment(payment.inserted_at).format('MMMM Do YYYY'),
      'Application Fee',
      toCurr(payment.amount),
      '',
      toCurr(payment.amount)
    ],
    [
      moment(payment.inserted_at).format('MMMM Do YYYY'),
      'Application Payment',
      '',
      toCurr(payment.amount),
      '$0.00'
    ]
  ];
  if (admin_payment.amount) {
    rows.push([
      moment(admin_payment.inserted_at).format('MMMM Do YYYY'),
      'Administration Fee',
      toCurr(admin_payment.amount),
      '',
      toCurr(admin_payment.amount)
    ]);
    rows.push([
      moment(admin_payment.inserted_at).format('MMMM Do YYYY'),
      'Administration Fee',
      '',
      toCurr(admin_payment.amount),
      '$0.00'
    ]);
  }

  const doc = new JsPDF('p', 'pt', 'a4');
  doc.autoTable({
    head: [columns],
    body: rows,
    theme: 'grid',
    headStyles: {fillColor: [5, 55, 135]},
    didDrawPage: function (data) {
      doc.text(headerString, 40, 30);
    }
  });
  doc.output('bloburl');

  return {csv: [columns].concat(rows), pdf: doc};
}


const date = (new Date(Date.now()).toLocaleString().split(',')[0]);

class FileExport extends Component {
  render() {
    const {toggle, application} = this.props;
    const {pdf, csv} = PDFCon(application);
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