import React from 'react';
import {connect} from "react-redux";
import {Button, Col, Row, Table, Input} from "reactstrap";
import JsPDF from 'jspdf';
import 'jspdf-autotable';
import moment from "moment";
import {toCurr} from "../../../../utils";
import DatePicker from "../../../../components/datePicker";
import Select from "../../../../components/select";
import actions from '../../actions';

const invoiceLevel = (daysLate) => {
  if (daysLate < 31) return 1;
  if (daysLate < 61) return 2;
  if (daysLate < 91) return 3;
  return 4;
};

function Filters(props){
       const {payer_id, date, amount} = props.filters
        return <>
          <Col>
            <div className='labeled-box'>
              <Select isClearable={true} name='payer_id' onChange={props.changeFilter} options={props.payers.map(p => ({label: p.name, value: p.id}))} value={payer_id}/>
              <div className='labeled-box-label'>Payer</div>
            </div>
          </Col>
          <Col>
            <div className='labeled-box'>
              <DatePicker name='date' onChange={props.changeDate} value={date}/>
              <div className='labeled-box-label'>Date</div>
            </div>
          </Col>
          <Col>
            <div className='labeled-box'>
              <Input name='amount' onChange={props.changeFilter} value={amount}/>
              <div className='labeled-box-label'>Amount</div>
            </div>
          </Col>
        </>;
}


class AgingReport extends React.Component {
  state = {
    overallTotals: [0, 0, 0, 0, 0],
    filters: {date: moment().format('YYYY-MM-DD'), payer_id: null, amount: ''}
  };

  static getDerivedStateFromProps(props, state) {
    let overallTotals = [0, 0, 0, 0, 0];
    if (props.reportData && props.reportData.length > 0) {
      props.reportData.forEach(payee => {
        let totals = [0, 0, 0, 0, 0];
        payee.invoices.forEach(invoice => {
          totals[0] = totals[0] + invoice.amount;
          const level = invoiceLevel(invoice.days_late);
          totals[level] = totals[level] + invoice.amount;
        });
        totals.forEach((t, i) => {
          overallTotals[i] = overallTotals[i] += parseFloat(t)
        });
      });
    }
    return {overallTotals: overallTotals}
  }

  filtered(){
    const {filters} = this.state;
    const {reportData, payers} = this.props;
    return reportData.filter(d => {
      if (filters.amount && d.amount != parseFloat(filters.amount)) return false;
      if (filters.payer_id && d.payee != payers[filters.payer_id].name) return false;
      return true;
    })
  }

  pdfExport() {
    const {property, reportData} = this.props;
    const {overallTotals} = this.state;
    const doc = new JsPDF({orientation: 'landscape'});
    const headers = ['Payee', 'Invoice Notes', 'Invoice Date', 'Account', 'Invoice #',
      'Current Owed', '0-30 days', '31-60 days', '61-90 days', 'Over 90 days'];

    const exportPDF = [];
    exportPDF.push(['Overall Total:', '', '', '', '', toCurr(overallTotals[0]), toCurr(overallTotals[1]), toCurr(overallTotals[2]), toCurr(overallTotals[3]), toCurr(overallTotals[4])]);
    reportData.forEach(payee => {
      const totals = [0, 0, 0, 0, 0];
      exportPDF.push([payee.payee, '', '', '', '', '', '', '', '', '']);
      payee.invoices.forEach(invoice => {
        totals[0] += totals[0] + invoice.amount;
        const level = invoiceLevel(invoice.days_late);
        totals[level] = totals[level] + invoice.amount;
        const row = ['', invoice.notes, invoice.date, invoice.account, invoice.number, toCurr(invoice.amount), '$0.00', '$0.00', '$0.00', '$0.00'];
        row[level + 5] = toCurr(invoice.amount);
        exportPDF.push(row);
      });
      exportPDF.push(['Total:', '', '', '', ''].concat(totals.map(t => toCurr(t))));
    });
    exportPDF.push(['Overall Total:', '', '', '', '', toCurr(overallTotals[0]), toCurr(overallTotals[1]), toCurr(overallTotals[2]), toCurr(overallTotals[3]), toCurr(overallTotals[4])]);
    doc.text(14, 15, `Payables Aging Report - ${property.name}`);
    doc.setFontSize(10);
    doc.text(14, 21, moment().format("MM/DD/YY"));
    doc.setFontSize(4);
    doc.autoTable({
      startY: 24, head: [headers], body: exportPDF, theme: 'grid',
      headStyles: {fillColor: [5, 55, 135], fontSize: 8}, columnStyles: {
        0: {cellWidth: 48, fontStyle: 'bold', fontSize: 8},
        1: {cellWidth: 20, fontSize: 8},
        2: {cellWidth: 22, fontSize: 8},
        3: {cellWidth: 40, fontSize: 8},
        4: {cellWidth: 30, fontSize: 8},
        5: {cellWidth: 24, fontSize: 8},
        6: {cellWidth: 21, fontSize: 8},
        7: {cellWidth: 21, fontSize: 8},
        8: {cellWidth: 21, fontSize: 8},
        9: {cellWidth: 21, fontSize: 8}
      }
    });
    doc.save(`${property.name}_${moment().format("MM/DD/YY")}_Aging_Report.pdf`)
  }

  changeDate(e) {
    this.changeFilter(e)
    actions.fetchDatedReport('aging', this.props.property, e.target.value.format('YYYY-MM-DD'));
  }

  changeFilter({target: {name, value}}){
    this.setState({filters: {...this.state.filters, [name]: value}})
  }

  render() {
    const {reportData, payers} = this.props;
    const {overallTotals, filters} = this.state;
    return <>
    <Row className='p2 mt-5'>
      <Col className='text-center'>
      <h1>Aging Report</h1>
      </Col>
    </Row>
      <Row className="p-5">
        <Filters changeDate={this.changeDate.bind(this)} changeFilter={this.changeFilter.bind(this)} filters={filters} payers={payers}/>
        <Col className="d-flex align-items-center justify-content-between">
          <Button size="sm" color="success" outline onClick={this.pdfExport.bind(this)}>
            Download PDF
          </Button>
        </Col>
      </Row>
      <Row className='p-5'>
        <Col xs={12}>
          <Table size='sm' className="data-table">
            <thead>
            <tr>
              <th>Payee</th>
              <th>Invoice Notes</th>
              <th>Invoice Date</th>
              <th>Account</th>
              <th>Invoice #</th>
              <th>Current Owed</th>
              <th>0-30 days</th>
              <th>31-60 days</th>
              <th>61-90 days</th>
              <th>Over 90 days</th>
            </tr>
            </thead>
            <tbody>
            <tr style={{background: '#5dbd77'}}>
              <th className="font-weight-bold" colSpan={5}>Overall Totals:</th>
              <th className="font-weight-bold">{toCurr(overallTotals[0])}</th>
              <th className="font-weight-bold">{toCurr(overallTotals[1])}</th>
              <th className="font-weight-bold">{toCurr(overallTotals[2])}</th>
              <th className="font-weight-bold">{toCurr(overallTotals[3])}</th>
              <th className="font-weight-bold">{toCurr(overallTotals[4])}</th>
            </tr>
            {this.filtered().map(payee => {
              const totals = [0, 0, 0, 0, 0];
              return <React.Fragment key={payee.id}>
                <tr>
                  <td>{payee.payee}</td>
                  <td colSpan={9}/>
                </tr>
                {payee.invoices.map(invoice => {
                  totals[0] = totals[0] + invoice.amount;
                  const level = invoiceLevel(invoice.days_late);
                  totals[level] = totals[level] + invoice.amount;
                  return <tr key={invoice.id}>
                    <td className="border-0"/>
                    <td className="border-0"><ul>{[invoice.notes, invoice.inv_notes].map(n => n && <li>{n}</li>)}</ul></td>
                    <td className="border-0">{invoice.date}</td>
                    <td className="border-0">{invoice.account}</td>
                    <td className="border-0">
                      <a href={`/invoices/${invoice.invoice_id}`} target="_blank">{invoice.number}</a>
                    </td>
                    <td className="border-0">{toCurr(invoice.amount)}</td>
                    <td className="border-0">
                      {level === 1 ? toCurr(invoice.amount) : '$0.00'}
                    </td>
                    <td className="border-0">
                      {level === 2 ? toCurr(invoice.amount) : '$0.00'}
                    </td>
                    <td className="border-0">
                      {level === 3 ? toCurr(invoice.amount) : '$0.00'}
                    </td>
                    <td className="border-0">
                      {level === 4 ? toCurr(invoice.amount) : '$0.00'}
                    </td>
                  </tr>;
                })}
                <tr style={{background: '#dee2e6'}}>
                  <td colSpan={5} className="font-weight-bold">Total:</td>
                  <td className="font-weight-bold">{toCurr(totals[0])}</td>
                  <td className="font-weight-bold">{toCurr(totals[1])}</td>
                  <td className="font-weight-bold">{toCurr(totals[2])}</td>
                  <td className="font-weight-bold">{toCurr(totals[3])}</td>
                  <td className="font-weight-bold">{toCurr(totals[4])}</td>
                </tr>
              </React.Fragment>;
            })}
            <tr style={{background: '#5dbd77'}}>
              <th className="font-weight-bold" colSpan={5}>Overall Totals:</th>
              <th className="font-weight-bold">{toCurr(overallTotals[0])}</th>
              <th className="font-weight-bold">{toCurr(overallTotals[1])}</th>
              <th className="font-weight-bold">{toCurr(overallTotals[2])}</th>
              <th className="font-weight-bold">{toCurr(overallTotals[3])}</th>
              <th className="font-weight-bold">{toCurr(overallTotals[4])}</th>
            </tr>
            </tbody>
          </Table>
        </Col>
      </Row>
    </>;
  }
}

export default connect(({property, reportData, payers}) => {
  return {property, reportData, payers};
})(AgingReport);
