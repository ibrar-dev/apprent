import React from 'react';
import {connect} from 'react-redux';
import {Row, Col, Button} from 'reactstrap';
import Pagination from '../../../components/pagination';
import Check from './check';
import CheckDetails from './checkDetails';
import Select from '../../../components/select';
import setLoading from '../../../components/loading';
import confirmation from '../../../components/confirmationModal';
import actions from '../actions';
import {toCurr} from "../../../utils";
import printPdf from "../../../utils/pdfPrinter";

const headers = [
  {label: '', min: true},
  {label: '', min: true},
  {label: 'Number', sort: 'number'},
  {label: 'Payee', sort: 'payee'},
  {label: 'Amount', sort: (dataset1, dataset2) => parseFloat(dataset1.amount) > parseFloat(dataset2.amount) ? 1 : -1},
  {label: 'Bank Account', sort: 'bank_account.name'},
  {label: 'Date', sort: (dataset1, dataset2) => new Date(dataset1.date) > new Date(dataset2.date) ? 1 : -1},
  {label: '', min: true},
];

class Checks extends React.Component {
  state = {};

  check() {
    this.setState({...this.state, check: !this.state.check});
  }

  deleteSelected() {
    confirmation('Delete all selected checks?').then(() => {
      let cascade = false;
      confirmation('Also mark invoices as unpaid?').then(() => cascade = true).finally(() => {
        this.props.selectedChecks.forEach(check => {
          actions.deleteCheck({id: check.id, cascade: cascade});
          actions.unselectCheck(check);
        });
      });
    });
  }

  printSelected() {
    const {selectedChecks} = this.props;
    const selected = selectedChecks.map(s => s.id);
    setLoading(true);
    actions.printChecks(selected).then(r => {
      printPdf(r.data.base64);
    }).finally(() => setLoading(false));
  }

  _filters() {
    const {filters} = this.props;
    return <Row style={{width: 200}}>
      <Col>
        <Select isClearable={true} value={filters.print_id}
                options={[{name: "All", id: 1}, {name: "Printed", id: 2}, {name: "Unprinted", id: 3}].map(p => {
                  return {label: p.name, value: p.id};
                })}
                onChange={actions.setFilter.bind(null, 'print_id')}/>
      </Col>
    </Row>
  }

  _titleBar() {
    const {selectedChecks} = this.props;
    const res = selectedChecks.reduce((acc, c) => c.amount ? acc + parseFloat(c.amount) : acc, 0);
    return <Row className="d-flex align-items-center">
      <Col>
        <Button color="danger"
                className="mr-2"
                onClick={this.deleteSelected.bind(this)}
                disabled={!selectedChecks.length}>
          Delete
        </Button>
        <Button color="info"
                onClick={this.printSelected.bind(this)}
                disabled={!selectedChecks.length}>
          Print
        </Button>
      </Col>
      <Col className="nowrap">
        <strong>Running Total: {toCurr(res)}</strong>
      </Col>
    </Row>
  }

  render() {
    const {checks, filters, selectedChecks} = this.props;
    const filtered = checks.filter(check => {
      const payeeMatch = !filters.payee_id || filters.payee_id === check.payee_id;
      const numberMatch = !filters.number || filters.number === check.number;
      const baMatch = !filters.account_id || filters.account_id === check.bank_account.id;
      const startDateMatch = !filters.date_start || filters.date_start.isSameOrBefore(check.date);
      const endDateMatch = !filters.date_end || filters.date_end.isSameOrAfter(check.date);
      const printMatch = !filters.print_id || filters.print_id === 1 || filters.print_id === 2 && check.document_url || filters.print_id === 3 && !check.document_url;
      return payeeMatch && numberMatch && printMatch && baMatch && startDateMatch && endDateMatch;
    });
    return <React.Fragment>
      <Pagination collection={filtered}
                  title={this._titleBar()}
                  component={Check}
                  headers={headers}
                  filters={this._filters()}
                  field="check"/>
      <div id="to-print" className="d-none d-print-block">
        {selectedChecks.map(check => {
          return <div style={{pageBreakAfter: 'always'}} key={check.id}>
            <CheckDetails check={check}/>
          </div>
        })}
      </div>
    </React.Fragment>;
  }
}

export default connect(({checks, selectedChecks, payees, filters}) => {
  return {checks, selectedChecks, payees, filters};
})(Checks);
