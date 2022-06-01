import React from 'react';
import {Button, ButtonGroup} from "reactstrap";
import {savePDF} from '@progress/kendo-react-pdf';
import {CSVLink} from "react-csv";

const defaultPDF = {paperSize: 'A4', fileName: `${name}.pdf`, margin: '1cm', scale: 0.6};

class Export extends React.Component {
  constructor(props) {
    super(props);
    this.dataRef = React.createRef();
  }

  exportPDF() {
    savePDF(this.dataRef.current, {...defaultPDF, ...this.props.pdfParams});
  }

  render() {
    const {children, createCSV, csvName, createExcel} = this.props;
    return (
      <section className="pdf-container">
        <ButtonGroup className="float-right">
          <Button style={{width: '50%'}} onClick={this.exportPDF.bind(this)} outline color="info" block>
              <i className="fas fa-2x fa-file-pdf"/>
          </Button>
            {createExcel && <Button style={{width: '50%'}} onClick={createExcel} outline color="info">
                <i className="fas fa-2x fa-file-excel"/>
            </Button>}
            {createCSV && <CSVLink style={{width: '50%'}} data={createCSV()} filename={csvName}
                                       className="btn btn-outline-info">
            <i className="fas fa-2x fa-file-csv"/>
          </CSVLink>}
        </ButtonGroup>
        <section className="pdf-body" ref={this.dataRef}>
          {children}
        </section>
      </section>
    )
  }
}

export default Export;