import React, {Component} from 'react';
import moment from 'moment';
import {connect} from 'react-redux';
import Pagination from "../../../../components/pagination";
import DatePicker from "../../../../components/datePicker";
import MonthPicker from "../../../../components/datePicker/monthPicker";
import {toCurr} from "../../../../utils";
import {Button, Table} from "reactstrap";
import PDFExport from "../../../../components/export/pdf";
import actions from '../../actions';

const titleRow = (row) => row.total && row.next_group ?
  <tr className="font-weight-bold" style={{background: '#c7cbcd'}}>
    <td colSpan={14}>
      {{down: 'Down Units', future: 'Future Residents', final: 'Final Total'}[row.next_group]}
    </td>
  </tr> : null;

class DownRow extends React.Component {
  render() {
    const {row} = this.props;
    return <>
      <tr className={row.total ? 'font-weight-bold' : ''}>
        <td>
          {row.total ? 'Totals:' : <a href={`/units/${row.unit_id}`} target="_blank">{row.number}</a>}
        </td>
        <td>{row.floor_plan}</td>
        <td/>
        <td>{toCurr(row.market_rent)}</td>
        <td colSpan={10}/>
      </tr>
      {titleRow(row)}
    </>
  }
}

class TableRow extends React.Component {
  render() {
    const {row, print} = this.props;
    if (row.status === 'DOWN' || row.type === 'down') return <DownRow row={row} print={print}/>;
    const tenant = row.tenant;
    return <>
      <tr className={row.total ? 'font-weight-bold' : ''}>
        {row.total ? <td colSpan={3}>Totals:</td> : <>
          <td>
            <a href={`/units/${row.unit_id}`} target="_blank">{row.number}</a>
          </td>
          <td className={print ? '' : 'nowrap'}>{row.floor_plan}</td>
          <td className={print ? '' : 'nowrap'}>
            {print && `${tenant.first_name} ${tenant.last_name}`}
            {!print && <a href={`/tenants/${tenant.id}`} target="_blank">{tenant.first_name} {tenant.last_name}</a>}
            {row.move_in && ` (Lease from: ${row.move_in})`}
          </td>
        </>}
        <td>{toCurr(row.market_rent)}</td>
        <td>{toCurr(row.market_rent - row.rent)}</td>
        <td>{toCurr(row.rent)}</td>
        <td>{toCurr(row.rent - row.actual_rent)}</td>
        <td>{toCurr(row.actual_rent || 0)}</td>
        <td>{toCurr(row.concession || 0)}</td>
        <td>{toCurr(row.actual_rent + row.concession)}</td>
        <td>{toCurr(row.receipts_current)}</td>
        <td>{toCurr(row.receipts_prior)}</td>
        <td>{toCurr(row.delinquency)}</td>
        <td>{toCurr(row.balance)}</td>
      </tr>
      {titleRow(row)}
    </>
  }
}

const headers = [
  {label: 'Unit', sort: 'number', min: true},
  {label: 'Floor Plan', sort: 'floor_plan'},
  {label: 'Resident'},
  {label: 'Market Rent', sort: 'market_rent'},
  {label: 'Loss/Gain to Lease'},
  {label: 'Potential Rent'},
  {label: 'Vacancy', sort: 'vacancy'},
  {label: 'Actual Rent'},
  {label: 'Concession', sort: 'concession'},
  // {label: 'Write Off'},
  {label: 'Rental Income'},
  {label: 'Receipts Current', sort: 'receipts_current'},
  {label: 'Receipts Prior', sort: 'receipts_prior'},
  {label: 'Delinquency'},
  {label: 'Prepay'}
];

class GrossPotentialRent extends Component {
  state = {date: moment(), postMonth: moment().startOf('month')};

  exportExcel() {
    const {date, postMonth} = this.state;
    const {property} = this.props;
    actions.fetchGPR({
      excel: true,
      property_id: property.id,
      date: date.format('YYYY-MM-DD'),
      post_month: postMonth.format('YYYY-MM-DD')
    });
  }

  change({target: {name, value}}) {
    const {property} = this.props;
    const newState = {...this.state, [name]: value};
    this.setState(newState);
    actions.fetchGPR({
      property_id: property.id,
      date: newState.date.format('YYYY-MM-DD'),
      post_month: newState.postMonth.format('YYYY-MM-DD')
    });
  }

  render() {
    const {reportData, property} = this.props;
    const {date, postMonth} = this.state;
    return <div>
      <Pagination collection={reportData}
                  title="Gross Potential Rent"
                  filters={<div className="d-flex">
                    <div className="ml-2">
                      <DatePicker value={date} name="date" onChange={this.change.bind(this)}/>
                    </div>
                    <div className="ml-2 bg-white">
                      <MonthPicker month={postMonth} name="postMonth" onChange={this.change.bind(this)}/>
                    </div>
                    <div className="ml-2 bg-white">
                      <PDFExport pdfParams={{landscape: true}} name={`Gross Potential Report.pdf`} invisible={true}
                                 target="report-data"/>
                    </div>
                    <div className="ml-2 bg-white">
                      <Button className="px-2 py-1 h-100" outline color="info" onClick={this.exportExcel.bind(this)}>
                        <i className="far fa-file-excel" style={{fontSize: '140%'}}/>
                      </Button>
                    </div>
                  </div>
                  }
                  field="row"
                  tableClasses="table-sm"
                  component={TableRow}
                  headers={headers}/>
      <div id="report-data" style={{display: 'none'}}>
        <h2 className="m-0">Gross Potential Rent</h2>
        <div>{property.name}</div>
        <div>As Of {date.format('MM/DD/YYYY')}</div>
        <div className="mb-2">Post Month {postMonth.format('MM/DD/YYYY')}</div>
        <div style={{fontSize: 12}}>
          <Table size="sm">
            <thead>
            <tr>{headers.map(h => <th key={h.label}>{h.label}</th>)}</tr>
            </thead>
            <tbody>
            {reportData.map(t => <TableRow print row={t} key={t.number}/>)}
            </tbody>
          </Table>
        </div>
      </div>
    </div>
  }
}

export default connect(({property, reportData}) => {
  return {property, reportData}
})(GrossPotentialRent)
