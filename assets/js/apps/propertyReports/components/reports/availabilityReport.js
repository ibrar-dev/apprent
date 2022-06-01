import React, {Component} from 'react';
import {connect} from 'react-redux';
import actions from "../../actions";
import moment from 'moment';
import Pagination from "../../../../components/pagination";
import {Button, ButtonGroup, Form, Modal, ModalHeader, ModalBody, Row, Col} from "reactstrap";
import jsPDF from "jspdf";
import {CSVLink} from "react-csv";
import boxscoreActions from '../../boxscore_actions';

const headers = [
  {label: 'Unit'},
  {label: 'Lease Start'},
  {label: 'Lease End'},
  {label: 'Move In'},
  {label: 'Move Out'},
  {label: 'Make Ready'},
  {label: 'Market Rent'},
  {label: 'Unit Status'},
];

class UnitInfo extends Component {
  state = {};

  toggleModal() {
    this.setState({modal: !this.state.modal});
  }

  render() {
    const {unit_info: {id, lease, prev_lease, number, status, market_rent: {market_rent, base_rent, base_feature, features}}} = this.props;
    const {modal} = this.state;
    const marketFeatures = base_rent.concat(base_feature);
    return <>
      <tr key={id}>
        <td>{number}</td>
        {lease && <td>{lease.start_date && moment(lease.start_date).format("MMM Do YY")}</td>}
        {lease && <td>{lease.end_date && moment(lease.end_date).format("MMM Do YY")}</td>}
        {lease && <td>{lease.expected_move_in && moment(lease.expected_move_in).format("MMM Do YY")}</td>}
        {lease && <td>{lease.move_out_date && moment(lease.move_out_date).format("MMM Do YY")}</td>}
        {prev_lease && <td>{prev_lease.completed ? <strong>{prev_lease.completed}</strong> : 'Not Ready'}</td>}
        <td><a onClick={this.toggleModal.bind(this)}>{market_rent}</a></td>
        <td>{status}</td>
      </tr>
      <Modal isOpen={modal} toggle={this.toggleModal.bind(this)}>
        <ModalHeader>Charges</ModalHeader>
        <ModalBody>
          <Col>
            <Row><strong>Base Rent Charges</strong></Row>
          </Col>
          <Row>
            <Col><strong>Name</strong></Col>
            <Col><strong>Price</strong></Col>
          </Row>
          {marketFeatures && marketFeatures.map(f => {
            return <Row>
              <Col>{f.name}</Col>
              <Col>{f.price}</Col>
            </Row>
          })}
          <br/>
          {features && features.length > 0 && <>
            <Col>
              <Row><strong>Default Charges</strong></Row>
            </Col>
            <Row>
              <Col><strong>Name</strong></Col>
              <Col><strong>Price</strong></Col>
            </Row>
          </>}
          {features && features.map(f => {
            return <Row>
              <Col>{f.name}</Col>
              <Col>{f.price}</Col>
            </Row>
          })}
        </ModalBody>
      </Modal>
    </>
  }
}

class Availability extends Component {
  state = {
    pdf: '#475f78',
    csv: '#475f78',
    d: [], nr: [], vr: [], vu: [], nu: [], a: [], occ: [], reno: [], usedArray: []
  };

  static getDerivedStateFromProps(props, state) {
    const {reportData} = props;
    if (reportData.length) {
      const arr = [];
      const d = boxscoreActions.down(reportData, arr);
      const nr = boxscoreActions.noticeRented(reportData, arr);
      const nu = boxscoreActions.noticeUnrented(reportData, arr);
      const occ = boxscoreActions.occupied(reportData, arr);
      const vu = boxscoreActions.vacantUnrented(reportData, arr);
      const a = vu.concat(nu);
      const reno = boxscoreActions.reno(reportData, arr);
      const vr = boxscoreActions.vacantRented(reportData, arr);
      state = {...state, reno: reno, d: d, nr: nr, vr: vr, nu: nu, vu: vu, occ: occ, a: a, usedArray: arr};
      return state;
    } else {
      return props;
    }
  }

  setMode(mode) {
    actions.setMode(mode);
  }

  hover(field, property) {
    this.setState({...this.state, [field]: property})
  }

  _filters() {
    const {mode} = this.props;
    return <Form className="ml-3" inline>
      <ButtonGroup className="mt-1 mr-1" style={{width: 600, height: 50}}>
        <Button size="sm" color="info" onClick={this.setMode.bind(this, 'all')} active={mode === 'all'}>All</Button>
        <Button size="sm" color="info" onClick={this.setMode.bind(this, 'vu')} active={mode === 'vu'}>
          Vacant Unrented
        </Button>
        <Button size="sm" color="info" onClick={this.setMode.bind(this, 'vr')} active={mode === 'vr'}>
          Vacant Rented
        </Button>
        <Button size="sm" color="info" onClick={this.setMode.bind(this, 'nu')} active={mode === 'nu'}>
          Notice Unrented
        </Button>
        <Button size="sm" color="info" onClick={this.setMode.bind(this, 'nr')} active={mode === 'nr'}>
          Notice Rented
        </Button>
        <Button size="sm" color="info" onClick={this.setMode.bind(this, 'd')} active={mode === 'd'}>Down</Button>
        <Button size="sm" color="info" onClick={this.setMode.bind(this, 'a')} active={mode === 'a'}>Available</Button>
        <Button size="sm" color="info" onClick={this.setMode.bind(this, 'reno')} active={mode === 'reno'}>Reno</Button>
        <Button size="sm" color="info" onClick={this.setMode.bind(this, 'occ')} active={mode === 'occ'}>Occupied No
          Notice</Button>
      </ButtonGroup>
      <div>
        <a onClick={this.pdfExport.bind(this)}
          // className="mr-1"
           style={{color: this.state.pdf, marginLeft: 15}}
           onMouseEnter={this.hover.bind(this, 'pdf', '#0056b3')}
           onMouseLeave={this.hover.bind(this, 'pdf', '#475f78')}
        >
          Download PDF
        </a>
        <CSVLink style={{textDecoration: 'none', color: this.state.csv, marginLeft: 15}}
                 onMouseEnter={this.hover.bind(this, 'csv', '#0056b3')}
                 onMouseLeave={this.hover.bind(this, 'csv', '#475f78')}
                 data={this.createExportArray().pdfArray}>Download CSV</CSVLink>
        {/*<CSVDownload data={this.createExportArray().pdfArray} target="_blank" />*/}
      </div>
    </Form>
  }

  filtered() {
    const {mode, reportData} = this.props;
    const {vu, reno, a, occ, vr, nu, nr, d, usedArray} = this.state;
    const unitData = reportData.filter(r => usedArray.includes(r.id));
    switch (mode) {
      case "vu":
        return vu;
      case "vr":
        return vr;
      case "nu":
        return nu;
      case "nr":
        return nr;
      case "d":
        return d;
      case "a":
        return a;
      case "occ":
        return occ;
      case "reno":
        return reno;
      default:
        return unitData;
    }
  }

  createArray(pdfArray, type, typeArray) {
    typeArray.forEach(({lease, number}) => {
      const completed = lease.completed ? lease.completed : 'Not Ready';
      pdfArray.push([number, type, lease.start_date, lease.end_date, lease.expected_move_in, lease.move_out_date, completed])
    });
    if (typeArray.length) pdfArray.push(["Total", type, typeArray.length])
  }

  createExportArray() {
    const {d, reno, nr, nu, vr, vu, a, occ} = this.state;
    const pdfArray = [];
    this.createArray(pdfArray, "Down", d);
    this.createArray(pdfArray, "Vacant Unrented", vu);
    this.createArray(pdfArray, "Vacant Rented", vr);
    this.createArray(pdfArray, "Avail", a);
    this.createArray(pdfArray, "Occupied", occ);
    this.createArray(pdfArray, "Reno", reno);
    return {pdfArray: pdfArray, d: d.length, nr: nr.length, nu: nu.length, vr: vr.length, vu: vu.length};
  }

  pdfExport() {
    const columns = ["Unit", "Availability Status", "Lease Start", "Lease End", "Move In", "Move Out", "Make Ready", "Unit Status"];
    const pdfArray = this.createExportArray().pdfArray;
    const doc = new jsPDF('l', 'pt', 'a4');
    doc.autoTable({
      head: [columns],
      body: pdfArray,
      theme: 'grid',
      headStyles: {fillColor: [5, 55, 135]},
      columnStyles: {
        0: {cellWidth: 90},
        1: {cellWidth: 120},
        2: {cellWidth: 90},
        3: {cellWidth: 90},
        4: {cellWidth: 90},
        5: {cellWidth: 90},
        6: {cellWidth: 90},
        7: {cellWidth: 90}
      },
      willDrawCell: drawCell,
      didDrawPageContent: function (data) {
        doc.text(headerString, 40, 30);
      }
    });
    let drawCell = data => {
      var doc = data.doc;
      var rows = data.table.body;
      if (rows.length === 1) {
      } else if (data.row.index === 2) {
        doc.setFontStyle("bold");
        doc.setFontSize("10");
        doc.setFillColor(255, 255, 255);
      }
    };
    doc.save('Availability Report.pdf');
  }

  render() {
    return <React.Fragment>
      <Pagination collection={this.filtered()}
                  title="Availability Report"
                  field="unit_info"
                  component={UnitInfo}
                  headers={headers}
                  filters={this._filters()}
      />
    </React.Fragment>
  }
}

export default connect(({reportData, property, mode, availability}) => {
  return {reportData, property, mode, availability}
})(Availability);
