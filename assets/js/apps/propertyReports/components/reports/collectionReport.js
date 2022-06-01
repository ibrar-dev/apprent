import React, {Component} from 'react';
import {connect} from 'react-redux';
import {Col, Button, Table, Input, InputGroupAddon} from 'reactstrap';
import {CSVLink} from "react-csv";
import moment from 'moment';
import JsPDF from 'jspdf';
import actions from '../../actions';
import {toCurr} from '../../../../utils';

class Collection extends Component {
  state = {
    // delinquency: true,
    description: '',
    filter: '',
    currentTenant: '',
    property_id: '',
    memos: {},
    asOfDate: moment().format('YYYY-MM-DD')
  };

  componentDidMount() {
    const property_id = this.props.property.id;
    this.setState({property_id: property_id})
  }

  residentsToShow(reportData) {
    const {memos} = this.state;
    return reportData.map(d => {
      if (memos[d.tenant_id]) {
        d['memo'] = memos[d.tenant_id];
      }
      return d;
    });
  }

  calculateTotal(reportData) {
    return toCurr(reportData.reduce((acc, t) => t.owed + acc, 0.00));
  }

  change(type, value) {
    this.setState({...this.state, [type]: !value})
  }

  createExportArray() {
    const {reportData} = this.props;
    const allReports = this.residentsToShow(reportData.filter(t => t.owed !== 0));
    return allReports.map(t => {
      return [t.unit, t.tenant_id, t.tenant, t.status, t.owed, t.memo]
    });
  }

  createCSV() {
    const header = [['Unit', 'ID', 'Last Name', 'Status', 'Total Owed', 'Memo']];
    const data = this.createExportArray();
    return header.concat(data);
  }

  pdfExport() {
    const {property} = this.props;
    const header = ['Unit', 'ID', 'Last Name', 'Status', 'Total Owed', 'Memo'];
    const pdfArray = this.createExportArray();
    const date = moment().format('MMMM DD, YYYY HH:mmA')
    const doc = new JsPDF('l', 'pt', 'a4');
    doc.text(40, 40, `Collection Report- ${property.name} ${date}`);
    doc.autoTable({
      startY: 50,
      head: [header],
      body: pdfArray,
      theme: 'grid',
      headStyles: {fillColor: [5, 55, 135]},
      columnStyles: {
        0: {cellWidth: 70},
        1: {cellWidth: 110},
        2: {cellWidth: 120},
        3: {cellWidth: 120},
        4: {cellWidth: 120},
        5: {cellWidth: 220}
      },
      didDrawPageContent: function (data) {
        doc.text(headerString, 40, 30);
      }
    });
    doc.output('collection_report');
    doc.save(`Collection-${property.name}-${date}.pdf`)
  }

  updateDescription(e) {
    const id = e.target.id;
    this.setState({...this.state, description: e.target.value, currentTenant: id});
  }

  updateFilter(e) {
    this.setState({...this.state, filter: e.target.value.toLowerCase()});
  }

  saveInteraction() {
    const id = parseInt(this.state.currentTenant);
    const allMemos = this.state.memos;
    allMemos[id] = this.state.description;
    actions.saveInteraction(id, this.state.description, parseInt(this.state.property_id));
    this.setState({...this.state, memos: allMemos, description: ''})
  }

  memoAction(id) {
    this.state.currentTenant === id ? this.state.description : '';
  }

  render() {
    const {reportData, property} = this.props;
    const {description} = this.state;
    const date = moment().format('MMMM DD, YYYY HH:mmA')
    return <React.Fragment>
      <div className="d-flex">
        <Button className="w-50"
                onClick={this.pdfExport.bind(this, this.calculateTotal(this.residentsToShow(reportData)))} outline
                block>Export PDF</Button>
        <CSVLink style={{width: '50%'}} data={this.createCSV()} filename={`Collection Report-${property.name} ${date}`}
                 className="btn btn-outline-secondary">Export CSV</CSVLink>
      </div>
      <Table striped>
        <thead>
        <tr>
          <th>Unit</th>
          <th>ID</th>
          <th>Last Name</th>
          <th>Status</th>
          <th>Total Owed</th>
          <th>Memo</th>
          <th/>
        </tr>
        </thead>
        <tbody>
        {reportData.length > 0 && reportData.map(t => {
          if (t.owed !== 0) {
            return <tr key={t.tenant_id}>
              <td>{t.unit}</td>
              <td><a target="_blank" href={`/tenants/${t.tenant_id}`}>{t.tenant_id}</a></td>
              <td>{t.tenant}</td>
              <td>{t.status}</td>
              <td>{toCurr(t.owed)}</td>
              <td colSpan={2}>
                <Input type="textarea" id={t.tenant_id}
                       onChange={this.updateDescription.bind(this)}
                       value={this.memoAction.bind(this)()}
                       placeholder="Memo"/>
                <InputGroupAddon addonType="append">
                  <Button id={t.tenant_id}
                          outline
                          color="info"
                          disabled={!description}
                          onClick={this.saveInteraction.bind(this)}>Save</Button>
                </InputGroupAddon>
              </td>
            </tr>
          }
        })}
        <tr>
          <th>Grand Total</th>
          <td/>
          <td/>
          <td/>
          <th>{this.calculateTotal(reportData)}</th>
        </tr>
        </tbody>
      </Table>
      <Col/>
      <Col/>
    </React.Fragment>
  }
}

export default connect(({property, reportData}) => {
  return {property, reportData}
})(Collection)
