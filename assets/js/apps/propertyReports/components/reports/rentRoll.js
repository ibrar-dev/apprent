import React, {Component} from 'react';
import {connect} from 'react-redux';
import {Row, Col, Table, Button, ButtonGroup, InputGroup, InputGroupAddon} from 'reactstrap';
import DatePicker from '../../../../components/datePicker';
import {toCurr, toAccounting} from "../../../../utils";
import actions from '../../actions';
import moment from 'moment';
import JsPDF from 'jspdf';
import 'jspdf-autotable';

class RentRoll extends Component {
  state = {
    asOfDate: moment().format('YYYY-MM-DD'),
    viewBalance: true,
    full: true,
    pdf: '#475f78',
    csv: '#475f78',
    rentRoll: 'real',
    d: [], nr: [], vr: [], vu: [], nu: [], a: [], occ: []
  };

  _applicants_payments(app) {
    const applicationPayment = app.payments.find(p => p.account === "Application Fees Income");
    const adminPayment = app.payments.find(p => p.account === "Administration Fees Income");
    const deposit = app.payments.find(p => p.account === "Security Deposit");
    return <React.Fragment>
      <td>
        <ul className="list-unstyled m-0">
          {applicationPayment && <li>Payment</li>}
          {adminPayment && <li>Admin</li>}
          {deposit && <li>Deposit</li>}
        </ul>
      </td>
      <td>
        <ul className="list-unstyled m-0">
          {applicationPayment && <li>{applicationPayment.amount}</li>}
          {adminPayment && <li>{adminPayment.amount}</li>}
          {deposit && <li>{deposit.amount}</li>}
        </ul>
      </td>
    </React.Fragment>
  }

  calculateTotal(reportData) {
    let totalBalance = 0;
    if (reportData && reportData.length >= 1) {
      reportData.forEach(r => {
        if (r.actual_move_in && r.end_date) totalBalance += r.balance ? parseFloat(r.balance) : 0;
      });
    }
    return toCurr(totalBalance);
  }

  calculateChargesTotal(summary) {
    return summary.reduce((acc, a) => acc + Number(a.total), 0)
  }

  toggleRentRoll(rentRoll) {
    this.setState({rentRoll});
  }

  toggleViewBalance() {
    this.setState({viewBalance: !this.state.viewBalance})
  }

  changeDate({target: {value}}) {
    this.setState({
      asOfDate: moment(value).format('YYYY-MM-DD')
    }, () => actions.fetchDatedReport('rent_roll', this.props.property, moment(value).format('YYYY-MM-DD')))
  }

  createExportArray() {
    const {reportData: {rent_roll_real}} = this.props;
    const exportPDF = [];
    rent_roll_real && rent_roll_real.forEach(u => {
      const {resident, tenant_id, deposit_amount, actual_move_in, lease_end, move_out_date, balance} = u;
      const charges = u.charges.map(c => [c.name, c.amount]);
      if (charges.length === 0) {
        exportPDF.push([u.number, u.floor_plan, u.sq_footage, resident, tenant_id, '', '', '', deposit_amount, actual_move_in, lease_end, move_out_date, balance]);
      } else if (charges.length > 1) {
        exportPDF.push([u.number, u.floor_plan, u.sq_footage, resident, tenant_id, '', ...charges[0], deposit_amount, actual_move_in, lease_end, move_out_date, balance]);
        charges.slice(1).forEach(c => {
          exportPDF.push(['', '', '', '', '', '', ...c, '']);
        });
      } else {
        exportPDF.push([u.number, u.floor_plan, u.sq_footage, resident, tenant_id, '', ...charges[0], deposit_amount, actual_move_in, lease_end, move_out_date, balance]);
      }
    });
    return exportPDF;
  }

  createExportPotentArray() {
    const {reportData: {rent_roll_potent}} = this.props;
    const exportPDF = [];
    {
      rent_roll_potent && rent_roll_potent.length >= 1 && rent_roll_potent.forEach(u => {
        const charges = [];
        if (u.payment_amount) charges.push(['payment_amount', u.payment_amount]);
        if (u.admin_payment_amount) charges.push(['admin_payment_amount', u.admin_payment_amount]);
        if (u.deposit) charges.push(['deposit', u.deposit]);
        if (charges.length < 2) {
          const charge = charges[0] ? charges[0] : ['', ''];
          exportPDF.push([u.name, u.application_id, u.date, u.number, u.status, ...charge,])
        } else {
          exportPDF.push([u.name, u.application_id, u.date, u.number, u.status, ...charges[0]]);
          charges.slice(1).forEach(c => {
            exportPDF.push(['', '', '', ...c, '', '']);
          })
        }
      })
    }
    return exportPDF;
  }

  createExportCharge() {
    const {reportData: {charges_summary}} = this.props;
    if (charges_summary) {
      return charges_summary.map(a => {
        return [a.account, a.total]
      })
    } else {
      return []
    }
  }

  hover(field, property) {
    this.setState({...this.state, [field]: property})
  }

  downloadCSV() {
    const {asOfDate} = this.state;
    const {property} = this.props;
    actions.downloadRentRollCSV(property.id, asOfDate)
  }

  pdfExport() {
    const {property, reportData: {rent_roll_real}} = this.props;
    const {asOfDate} = this.state;
    const exportPDF = this.createExportArray();
    const doc = new JsPDF('l', 'pt', 'a4');
    const potents = this.createExportPotentArray();
    const header = ['Unit', 'Floor Plan', 'Sq Ft', 'Resident', 'Resident ID', 'Market Rent', 'Charges', 'Amount', 'Deposit Amount', 'Move In', 'Lease End', 'Move Out', 'Balance'];
    const potentHeader = ['Name', 'Application ID', 'Date', 'Unit', 'Status', 'Charges', 'Amount'];
    const total = this.calculateTotal(rent_roll_real);
    const bottom = [['Total', '', '', '', total]];
    const chargeSumHeader = ['Charge Code', 'Amount'];
    const chargeSum = this.createExportCharge();

    doc.text(40, 40, `Rent Roll - ${property.name} ${asOfDate}`);
    doc.autoTable({
      startY: 50, head: [header], body: exportPDF, theme: 'grid',
      headStyles: {fillColor: [5, 55, 135]}, columnStyles: {
        0: {cellWidth: 40},
        1: {cellWidth: 70},
        2: {cellWidth: 40},
        3: {cellWidth: 100},
        4: {cellWidth: 50},
        5: {cellWidth: 50},
        6: {cellWidth: 50},
        7: {cellWidth: 50},
        8: {cellWidth: 50},
        9: {cellWidth: 60},
        10: {cellWidth: 60},
        11: {cellWidth: 60},
        12: {cellWidth: 70}
      },
      didDrawPageContent: function (_) {
        doc.text(headerString, 40, 30);
      }
    });

    doc.autoTable({
      startY: doc.autoTable.previous.finalY, body: bottom, theme: 'grid',
      columnStyles: {
        0: {cellWidth: 100},
        1: {cellWidth: 100},
        2: {cellWidth: 100},
        3: {cellWidth: 100},
        4: {cellWidth: 100}
      },
      didDrawPageContent: function (data) {
        doc.text(headerString, 40, 30);
      }
    });
    doc.text(`Future/Potential Resident - ${property.name} ${asOfDate}`, 40, doc.autoTable.previous.finalY + 40);
    doc.autoTable({
      startY: doc.autoTable.previous.finalY + 50, head: [potentHeader], body: potents, theme: 'grid',
      columnStyles: {
        0: {cellWidth: 100},
        1: {cellWidth: 100},
        2: {cellWidth: 100},
        3: {cellWidth: 100},
        4: {cellWidth: 100}
      },
      didDrawPageContent: function (data) {
        doc.text(headerString, 40, 30);
      }
    });

    doc.text(`Charge Summary - ${property.name} ${asOfDate}`, 40, doc.autoTable.previous.finalY + 40);
    doc.autoTable({
      startY: doc.autoTable.previous.finalY + 50, head: [chargeSumHeader], body: chargeSum, theme: 'grid',
      columnStyles: {0: {cellWidth: 200}, 1: {cellWidth: 200}},
      didDrawPageContent: function (data) {
        doc.text(headerString, 40, 30);
      }
    });
    doc.save(`${property.name}_${moment(asOfDate).format("MM/DD/YY")}_RR.pdf`)
  }

  findPotentialResident() {
    const {reportData: {rent_roll_potent}} = this.props;
    return <>
      {rent_roll_potent && <tbody>
      {rent_roll_potent.length >= 1 && rent_roll_potent.map((u, i) => {
        return <tr key={i}>
          <td>{u.name}</td>
          <td>{u.application_id}</td>
          <td>{u.number}</td>
          <td>{u.floor_plan}</td>
          <td>{u.sq_footage}</td>
          {this._applicants_payments(u)}
          <td>{u.date}</td>
          <td>{u.status}</td>
        </tr>
      })}
      </tbody>}
    </>
  }

  render() {
    const {reportData: {rent_roll_real, charges_summary}} = this.props;
    const {asOfDate, viewBalance, rentRoll} = this.state;
    return <React.Fragment>
      <div className="mt-1 ml-1">
        <ButtonGroup>
          <Button size="sm" color="info" active={rentRoll === 'real'}
                  onClick={this.toggleRentRoll.bind(this, 'real')}>Residents</Button>
          <Button size="sm" color="info" active={rentRoll === 'potent'}
                  onClick={this.toggleRentRoll.bind(this, 'potent')}>Potential Residents</Button>
          <Button size="sm" color="info" active={rentRoll === 'charge_summary'}
                  onClick={this.toggleRentRoll.bind(this, 'charge_summary')}>Charge Summary</Button>
        </ButtonGroup>
      </div>
      <Row className='d-flex align-items-center mt-3 mb-2 mx-0'>
        <Col sm={6}>
          <div className="labeled-box">
            <InputGroup>
              <DatePicker onChange={this.changeDate.bind(this)} value={asOfDate} name="start"/>
              <InputGroupAddon addonType="append">
                <Button size="sm" color="success" outline onClick={this.pdfExport.bind(this)}>
                  Download PDF
                </Button>
                <Button size="sm" color="info" outline onClick={this.downloadCSV.bind(this)}>
                  Excel
                </Button>
              </InputGroupAddon>
            </InputGroup>
            <div className="labeled-box-label">Date</div>
          </div>
        </Col>
        {rentRoll === 'real' && <Col className="d-flex justify-content-end">
          <b>Total Balance:</b>
          {rent_roll_real && <span className="ml-2">{rent_roll_real && this.calculateTotal(rent_roll_real)}</span>}
        </Col>}
      </Row>
      {rentRoll === 'real' && <Table className="sticky-header">
        <thead>
        <tr>
          <th>Unit</th>
          <th className="nowrap">Floor Plan</th>
          <th className="nowrap min-width">Square Footage</th>
          <th>Resident</th>
          <th className="nowrap">Resident ID</th>
          <th className="nowrap">Market Rent</th>
          <th>Charges</th>
          <th>Amount</th>
          <th className="nowrap">Deposit Amount</th>
          <th className="nowrap">Move In</th>
          <th className="nowrap">Lease End</th>
          <th className="nowrap">Move Out</th>
          <th className="nowrap" onClick={this.toggleViewBalance.bind(this)}
              style={{cursor: 'pointer'}}>{viewBalance ? 'Hide ' : 'View '}Balance
          </th>
        </tr>
        </thead>
        {rent_roll_real && <tbody>
        {rent_roll_real.map(u => {
          return <tr key={u.id}>
            <td><a href={`/units/${u.id}`} target="_blank">{u.number}</a></td>
            <td>{u.floor_plan}</td>
            <td className="text-center">{u.sq_footage}</td>
            <td><a href={`/tenants/${u.tenant_id}`} target="_blank">{u.resident}</a></td>
            <td><a href={`/tenants/${u.tenant_id}`} target="_blank">{u.tenant_id}</a></td>
            <td>{toCurr(u.market_rent)}</td>
            <td>
              <ul className="list-unstyled m-0">
                {u.charges.map(c => {
                  return <li key={c.id || c.account}>{c.account}</li>
                })}
              </ul>
            </td>
            <td>
              <ul className="list-unstyled m-0">
                {u.charges.map(c => {
                  return <li key={c.id || c.account}>{toCurr(c.amount)}</li>
                })}
              </ul>
            </td>
            <td>{u.deposit_amount ? toCurr(u.deposit_amount) : ''}</td>
            <td className="nowrap">{u.actual_move_in}</td>
            <td className="nowrap">{u.end_date}</td>
            <td className="nowrap">{u.move_out_date ? u.move_out_date : ''}</td>
            <td
              className={`text-${u.balance <= 0 ? 'success' : 'danger'}`}>{viewBalance && u.tenant_id && toCurr(u.balance)}</td>
          </tr>
        })}
        </tbody>}
      </Table>}
      {rentRoll === 'charge_summary' && rent_roll_real && <Table size="sm">
        <thead>
        <tr>
          <th colSpan={2}>Summary of Charges</th>
        </tr>
        <tr>
          <th>Account</th>
          <th>Amount</th>
        </tr>
        </thead>
        <tbody>
        {charges_summary.map((a, i) => {
          return <tr key={i}>
            <td>{a.account}</td>
            <td>{toAccounting(a.total)}</td>
          </tr>
        })}
        <tr>
          <th>Total:</th>
          <th>{toAccounting(this.calculateChargesTotal(charges_summary))}</th>
        </tr>
        </tbody>
      </Table>}
      {rentRoll === 'potent' && <Table>
        <thead>
        <tr>
          <th>Applicant</th>
          <th className="nowrap">Applicant ID</th>
          <th>Unit</th>
          <th className="nowrap">Floor Plan</th>
          <th className="nowrap">Square Footage</th>
          <th>Charges</th>
          <th>Amount</th>
          <th className="nowrap">Date Applied</th>
          <th>Status</th>
        </tr>
        </thead>
        {this.findPotentialResident()}
      </Table>}
    </React.Fragment>
  }
}

export default connect(({property, reportData, availability}) => {
  return {property, reportData, availability}
})(RentRoll)
