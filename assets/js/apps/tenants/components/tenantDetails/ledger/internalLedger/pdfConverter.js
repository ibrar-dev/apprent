import React from 'react';
import JsPDF from 'jspdf';
import 'jspdf-autotable';
import moment from "moment";
import {toCurr} from '../../../../../../utils';

const description = (element) => {
  if (element.description) return element.description;
  if (element.nsf_id) return `NSF - ${element.payment_description} ${element.payment_transaction_id}`;
  return element.account;
};

export function PDFCon(array) {
  const columns = ["Date", "Account", "Charge", "Payment", "Balance"];
  const pdfArray = [];
  const csvArray = [columns];
  let balance = 0;
  const headerString = "Ledger";

  array.forEach((element) => {
    balance = balance + (element.amount * (element.isPayment ? -1 : 1));
    const row = [
      moment(element.bill_date || element.inserted_at).format('MMMM Do YYYY'),
      description(element),
      element.account ? `${toCurr(element.amount)}` : '',
      element.isPayment ? `${toCurr(element.amount)}` : '',
      `${toCurr(balance)}`];
    pdfArray.push(row);
    csvArray.push(row);
  });


  const doc = new JsPDF('p', 'pt', 'a4');
  doc.autoTable({
    head: [columns],
    body: pdfArray,
    theme: 'grid',
    headStyles: {fillColor: [5, 55, 135]},
    didDrawPage: function (data) {
      doc.text(headerString, 40, 30);
    }
  });
  doc.output('bloburl');

  return {csv: csvArray, pdf: doc};
}