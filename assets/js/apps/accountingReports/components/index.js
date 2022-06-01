import React from 'react';
import {connect} from 'react-redux';
import {Row, Col, Button, Card, CardHeader, CardBody} from 'reactstrap';
import moment from 'moment';
import Report from './report';
import {ValidatedSelect, validate} from '../../../components/validationFields';
import confirmation from '../../../components/confirmationModal';
import actions from '../actions';
import FancyCheck from '../../../components/fancyCheck';
import MonthPicker from '../../../components/datePicker/monthPicker';
import PDFExport from '../../../components/export/pdf';
import reportKey from './reportKey';

const defaultReports = [
  {
    name: 'Income Statement',
    label: 'Income Statement',
    value: 'income'
  },
  {
    name: 'Balance Sheet',
    label: 'Balance Sheet',
    value: 'balance'
  },
  {
    name: '12 Month Income',
    label: '12 Month Income',
    value: 't12'
  },
  {
    name: 'General Ledger',
    label: 'General Ledger',
    value: 'gl'
  },
  {
    name: 'Budget Comparison',
    label: 'Budget Comparison',
    value: 'budget'
  }
];

class Reports extends React.Component {
  state = {
    suppressZeros: false,
    title: '',
    start: moment(),
    end: moment(),
    id: 'income',
    book: 'accrual',
    balance: false,
    glAccountId: -1
  };

  change({target: {name, value}}) {
    const {balance} = this.state;
    if (name === 'start' && !balance && value.isAfter(this.state.end)) {
      return confirmation('Start date cannot be after the end date', {noCancel: true});
    }
    if (name === 'end' && value.isBefore(this.state.start)) {
      return confirmation('End date cannot be before the start date', {noCancel: true});
    }
    if (name === 'id' && value === 't12') {
      this.setState({id: value, start: moment().startOf('y'), end: moment().endOf('y'), dirty: true, balance: false})
    } else if (name === 'id') {
      const {templates} = this.props;
      this.setState({
        id: value,
        balance: value === 'balance' || (parseInt(value) ? templates.find(t => t.id === value).is_balance : false),
        dirty: true,
        deposit: false
      });
    } else {
      this.setState({[name]: value});
    }
  }

  runReport() {
    validate(this).then(() => {
      const {id, property_ids, start, end, book, balance} = this.state;
      actions.runReport({
        id,
        property_ids,
        date: start.format('YYYY-MM-DD'),
        start_date: start.format('YYYY-MM-DD'),
        end_date: balance ? null : end.format('YYYY-MM-DD'),
        book
      }).then(({data: {result}}) => {
        this.setState({result, resultId: id, dirty: false});
      });
    });
  }

  toggleSuppressZeros() {
    this.setState({suppressZeros: !this.state.suppressZeros})
  }

  reportName() {
    const {start, end, resultId, balance} = this.state;
    const key = {gl: 'General Ledger', balance: 'Balance Sheet', income: 'Income Statement', t12: 'T-12 Income'};
    return `${key[resultId]} ${start.format('L')}${balance ? '' : ' - ' + end.format('L')}`;
  }

  exportExcel() {
    const {id, property_ids, start, end, suppressZeros, book, glAccountId} = this.state;
    actions.exportExcel({id, property_ids, start, end, suppressZeros, book, glAccountId})
  }

  setGlAccount(glAccountId) {
    this.setState({glAccountId});
  }

  render() {
    const {templates, properties} = this.props;
    const reportOptions = [
      {label: 'Standard', options: defaultReports},
      {
        label: 'Custom', options: templates.map(t => {
          return {label: t.name, value: t.id}
        })
      }
    ];
    const {id, property_ids, start, end, result, balance, book, deposit, suppressZeros, resultId, dirty} = this.state;
    const change = this.change.bind(this);
    const Report = reportKey[id];
    return <Card>
      <CardHeader>Reports</CardHeader>
      <CardBody>
        <Row>
          <Col sm={5}>
            <div className="labeled-box">
              <ValidatedSelect context={this}
                               validation={v => !!v}
                               feedback="Select a report"
                               onChange={change} value={id} name="id"
                               options={reportOptions}/>
              <div className="labeled-box-label">Report</div>
            </div>
          </Col>
          <Col sm={2}>
            <div className="labeled-box">
              <ValidatedSelect context={this}
                               validation={v => !!v}
                               feedback="Select a report type"
                               disabled={!!deposit} onChange={change} value={book} name="book" options={[
                {label: 'Cash', value: 'cash'}, {label: 'Accrual', value: 'accrual'}]}/>
              <div className="labeled-box-label">Type</div>
            </div>
          </Col>
          <Col sm={5}>
            <div className="labeled-box">
              <ValidatedSelect context={this}
                               validation={v => !!v}
                               feedback="Select a property"
                               multi
                               onChange={change} value={property_ids} name="property_ids" options={properties.map(p => {
                return {label: p.name, value: p.id}
              })}/>
              <div className="labeled-box-label">Property</div>
            </div>
          </Col>
        </Row>
        <Row className="my-3">
          <Col sm={5} className="d-flex align-items-center">
            {balance && <div className="labeled-box w-50">
              <MonthPicker onChange={change} month={start} name="start"/>
              <div className="labeled-box-label">Date</div>
            </div>}
            {!balance && <>
              <div className="labeled-box">
                <MonthPicker onChange={change} month={start} name="start"/>
                <div className="labeled-box-label">From</div>
              </div>
              <div className="labeled-box ml-4 w-100">
                <MonthPicker onChange={change} month={end} name="end"/>
                <div className="labeled-box-label">To</div>
              </div>
            </>}
            {result && <label className="d-flex align-items-center justify-content-end w-50 m-0">
              <FancyCheck inline value={suppressZeros} onChange={this.toggleSuppressZeros.bind(this)}/>
              <div className="ml-2">Suppress Zeros</div>
            </label>}
          </Col>
          <Col>
            <div className="d-flex">
              <Button color="success" onClick={this.runReport.bind(this)} block>
                Run Report
              </Button>
              <div className="ml-2">
                <PDFExport pdfParams={{landscape: ['t12', 'gl'].includes(resultId)}}
                           name={`${this.reportName()}.pdf`} invisible={resultId === 'gl'}
                           buttonProps={{disabled: !result}} target="report-data"/>
              </div>
              <div className="ml-2">
                <Button outline color="info" disabled={!result} onClick={this.exportExcel.bind(this)}>
                  <i className="far fa-file-excel"/>
                </Button>
              </div>
            </div>
          </Col>
        </Row>
        {result && !dirty &&
        <Report parent={this} result={result} suppressZeros={suppressZeros} dates={{start_d: start, end_d: end}}/>}
      </CardBody>
    </Card>
  }
}

export default connect(({templates, properties}) => {
  return {templates, properties};
})(Reports);
