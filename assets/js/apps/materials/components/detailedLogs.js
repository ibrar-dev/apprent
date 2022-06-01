import React, {Component, Fragment} from 'react';
import {Modal, ModalHeader, ModalBody, Button} from 'reactstrap';
import moment from 'moment';
import Pagination from '../../../components/pagination';
import FileExport from "../../workOrders/components/fileExport";
import jsPDF from "jspdf";
import 'jspdf-autotable';


class Log extends Component {
  state = {modal: false};

  render() {
    const {log} = this.props;
    return <tr>
      <td>{log.property}</td>
      <td>{log.material}</td>
      <td>{log.quantity}</td>
      <td>${log.quantity * log.material_cost}</td>
      <td>{moment(log.date).format("YYYY-MM-DD")}</td>
    </tr>
  }
}

class DetailedLogs extends Component {
  state = {};

  headers = [
    {label: 'Property', sort: 'property'},
    {label: 'Material', sort: 'material'},
    {label: 'Quantity', sort: 'quantity'},
    {label: 'Cost', sort: null},
    {label: 'Date', sort: 'date'}
  ];

  filterChange(e) {
    this.setState({...this.state, filterVal: e.target.value});
  }

  buildPDF_CSV() {
    const logs = [...new Set(this.props.logs.material)];
    let materialArray = [];
    const materialsColumn= ["Property"," Material", "Quantity", "Cost", "Date", "Stock"];
    for (let i = 0; i < logs.length; i++) {
      const date = moment.utc(logs[i].date).local().format("YYYY-MM-DD h:mm A");
      materialArray.push([logs[i].property, logs[i].material, logs[i].quantity, logs[i].material_cost, date, logs[i].stock])
    }
    const pdf = new jsPDF("p", "mm", "a4");
    pdf.text(13, 15, `Detailed logs for ${this.props.name} from ${moment(this.props.startDate).format("YYYY-MM-DD")} to ${moment(this.props.endDate).format("YYYY-MM-DD")}`);
    pdf.autoTable({head: [materialsColumn], body: materialArray, theme: 'grid', startY: 30, headStyles: {fillColor: [5, 55, 135]},columnStyles: {0: {cellWidth: 25}, 1: {cellWidth: 30}, 2: {cellWidth: 15}, 3: {cellWidth: 30}, 4: {cellWidth: 30}, 5: {cellWidth: 30}} ,didDrawPageContent: function(data) {
        pdf.text(headerString, 20, 20);
      }});
    pdf.save('Logs.pdf');
  }

  toggleExport() {
    this.setState({...this.state, modal: !this.state.modal})
  }

  render() {
    const {toggle, open, name, startDate, endDate, logs} = this.props;
    const {filterVal, pdf, csv, modal} = this.state;
    const filter = new RegExp(filterVal, 'i');
    return <Fragment>
      <Modal isOpen={open} toggle={toggle} size='lg'>
        <ModalHeader toggle={toggle}>
          Detailed Logs for {name} from <b>{moment(startDate).format("YYYY-MM-DD")}</b> to <b>{moment(endDate).format("YYYY-MM-DD")}</b>
        </ModalHeader>
        <ModalBody>
          <div className="mb-1">
            <Button outline color="success" block onClick={this.buildPDF_CSV.bind(this)}>Export</Button>
          </div>
          <Pagination title="Activity Logs"
                      collection={logs.filter(l => filter.test(l.property) || filter.test(l.material))}
                      component={Log}
                      filters={<input placeholder='Property or Material' className="form-control" value={filterVal || ''} onChange={this.filterChange.bind(this)}/>}
                      headers={this.headers}
                      field="log">
          </Pagination>
        </ModalBody>
        {pdf && <FileExport modal={modal} toggle={this.toggleExport.bind(this)} pdf={pdf} csv={csv}/>}
      </Modal>
    </Fragment>
  }
}

export default DetailedLogs;