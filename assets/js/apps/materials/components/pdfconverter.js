import React from 'react';
import jsPDF from 'jspdf';

export function PDFCon(array, filterVal){
  const filter = new RegExp(filterVal, 'i');
  const columns = ["Name", "Reference", "Item Cost", "Inventory", "Minimum Desired", "Amount Needed", "Total Cost"];
  var selectedColumn = [];
  var pdfArray = [];
  var csvArray = [];
  const headerString = `Materials`;
  array.filter(m => filter.test(m.ref_number) || filter.test(m.name)).forEach((material) => {
    pdfArray.push([material.name, material.ref_number, material.cost, material.inventory, material.desired, (material.desired - material.inventory) > 0 ? (material.desired - material.inventory) : null, (material.desired - material.inventory) > 0 ? `$${((material.desired - material.inventory) * material.cost)}` : null]);
    csvArray.push([material.name, material.ref_number, material.cost, material.inventory, material.desired, (material.desired - material.inventory) > 0 ? (material.desired - material.inventory) : null, (material.desired - material.inventory) > 0 ? `$${Math.round(((material.desired - material.inventory) * material.cost) * 100) / 100}` : null]);
    selectedColumn = columns;
    csvArray[0] = columns;
  });

  const doc = new jsPDF('p', 'pt', 'a4');
  doc.autoTable(selectedColumn, pdfArray, { theme: 'grid', headerStyles: {fillColor: [5, 55, 135]}, columnStyles: { 1: {columnWidth: 70}, 4: {columnWidth: 25}},addPageContent: function(data) {
      doc.text(headerString, 40, 30);
    }});
  doc.output('bloburl');

  return {csv: csvArray, pdf: doc};
}