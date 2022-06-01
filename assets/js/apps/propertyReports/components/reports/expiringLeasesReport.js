import React, {Component, Fragment} from 'react';
import {connect} from "react-redux";
import moment from 'moment';
import Pagination from "../../../../components/pagination";
import DatePicker from "../../../../components/datePicker";
import {Button, Table} from "reactstrap";
import PDFExport from "../../../../components/export/pdf";
import actions from '../../actions';
import ExpiringLeasesModal from '../report_component/expiringLeasesModal';

let headers = [
  {label: 'Floor Plan', sort: 'name'},
  // {label: 'Unit Count', sort: (p1, p2) => p1.units.length > p2.units.length ? 1 : -1},
  {label: 'Unit Count', sort: 'units'},
  {label: 'MTM', sort: (p1, p2) => p1.mtm.length > p2.mtm.length ? 1 : -1}
];

class TableRow extends Component {
  render() {
    const {row, print, setData} = this.props;
    return <tr>
      <td>{row.name}</td>
      <td className={print ? '' : 'nowrap'}>{row.units}</td>
      <td>{row.mtm.length}</td>
      {row.months.map((m, i) => {
        return <td className="cursor-pointer" key={i} onClick={print ? null : setData.bind(this, {...m, name: row.name})}>
          {m.units.length}
        </td>
      })}
    </tr>
  }
}

class ExpiringLeases extends Component {
  state = {
    date: moment()
  }

  change({target: {value}}) {
    const {property} = this.props;
    const {date} = this.state;
    this.setState({...this.state, date: value});
    actions.fetchDatedReport("expiring_leases", property, date.format('YYYY-MM-DD'));
  }

  setData(data) {
    let title = ""
    if (data) title = `Leases expiring for ${data.name} during the month of ${moment(data.month).format("MMMM, YYYY")}`
    this.setState({...this.state, data: data, title: title})
  }

  headersToDisplay() {
    const {date} = this.state;
    let months = [0,1,2,3,4,5,6,7,8,9,10,11].map(i => {
      return {label: moment(date).add(i, 'M').format("MM/YY")}
    });
    return headers.concat(months)
  }

  totalRow() {
    const {reportData} = this.props;
    if (!reportData || !reportData.length) return {units: 0, mtm: 0, months: []}
    const months = reportData.reduce((acc, p) => {
      p.months.forEach((m, i) => {
        acc[i] = (acc[i] || 0) + m.units.length
      })
      return acc;
    }, []);
    return reportData.reduce((acc, p) => {
      return {units: acc.units + p.units, mtm: acc.mtm + p.mtm.length, months: acc.months, total: acc.total}
    }, {units: 0, mtm: 0, months: months})
  }

  renderedTotalRow(data) {
    return  <tr className="table-primary">
      <th>Totals:</th>
      <th>{data.units}</th>
      <th>{data.mtm}</th>
      {data.months && data.months.map((m, i) => {
        return <th key={i}>{m}</th>
      })}
    </tr>
  }

  render() {
    const {reportData, property} = this.props;
    const {date, data, title} = this.state;
    const totalRow = this.totalRow();
    return <Fragment>
      {data && <ExpiringLeasesModal data={data} toggle={this.setData.bind(this, null)} title={title} />}
      <Pagination collection={reportData}
                  title="Expiring Leases by Month"
                  filters={<div className="d-flex">
                    <div className="ml-2">
                      <DatePicker value={date} name="date" onChange={this.change.bind(this)}/>
                    </div>
                    <div className="ml-2 bg-white">
                      <PDFExport pdfParams={{landscape: true}} name={`Expiring Leases by Month.pdf`} invisible={true}
                                 target="report-data"/>
                    </div>
                  </div>
                  }
                  field="row"
                  tableClasses="table-sm"
                  component={TableRow}
                  additionalProps={{setData: this.setData.bind(this)}}
                  totalRow={this.renderedTotalRow(totalRow)}
                  headers={this.headersToDisplay()} />
      <div id="report-data" style={{display: 'none'}}>
        <h2 className="m-0">Expiring Leases by Month</h2>
        <div>{property.name}</div>
        <div>As Of {date.format('MM/DD/YYYY')}</div>
        <div style={{fontSize: 12}}>
          <Table size="sm">
            <thead>
            <tr>{this.headersToDisplay().map(h => <th key={h.label}>{h.label}</th>)}</tr>
            </thead>
            <tbody>
            {reportData.map(t => <TableRow print row={t} key={t.id} />)}
            {this.renderedTotalRow(totalRow)}
            </tbody>
          </Table>
        </div>
      </div>
    </Fragment>
  }
}

export default connect(({property, reportData}) => {
  return {property, reportData}
})(ExpiringLeases)
