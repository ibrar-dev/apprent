import React, {Component} from 'react';
import Deposit from './deposit.js'
import Check from './check.js'
import {withRouter} from "react-router-dom";
import {toCurr} from "../../../utils";
import {connect} from 'react-redux';
import NSFPayment from './nsfPayment.js'
import Pagination from '../../../components/simplePagination';
import DateRangePicker from '../../../components/dateRangePicker'
import confirmation from '../../../components/confirmationModal'
import {
  Modal,
  Badge,
  ModalBody,
  Button,
  Row,
  Container,
  ButtonGroup,
  Col
} from 'reactstrap'
import FancyCheck from '../../../components/fancyCheck'
import actions from '../actions.js'
import AdvancedFilters from './filters.js';
import setLoading from '../../../components/loading';
import EditReconciliation from './newReconciliation'
import moment from 'moment'


function Transaction(props) {
  const {data, change} = props;
  const types = {
    batch: Deposit,
    nsf_payment: NSFPayment,
    check: Check,
    journal_income: Deposit,
    journal_expense: Check,
    payment_wo_batch: NSFPayment
  }
  const Component = types[data.type]
  return <Component data={data} change={change} />
}

const headers = {
  columns: [
  {label: "DATE"},
  {label: "REF NO."},
  {label: "CLEARED DATE"},
  {label: "TYPE"},
  {label: "PAYEE"},
  {label: "PAYMENT"},
  {label: "DEPOSIT"},
  {label: "MEMO"},
  {label: ""}
]
}

class Reconciliation extends Component {
  constructor(props) {
    super(props)
    this.state = {
      transactions: {},
      filters: {type: null},
      modalOpen: false
    }
  }

  componentDidMount() {
    this.fetchTransactions()
  }

  normalizeData(data){
    const newObject = {};
    data.forEach((t) => newObject[`${t.type}-${t.id}`] = t)
    return newObject;
  }

  fetchTransactions() {
    const posting_id = this.props.match.params.id;
    actions.fetchUnreconciledTransactions(posting_id, {filters: this.state.filters})
        .then(r => {
          this.normalizeData(r.data.transactions)
              this.setState({
                ...r.data,
                transactions: this.normalizeData(r.data.transactions),
                filters: {start_date: r.data.start_date, end_date: r.data.end_date, ...this.state.filters}
              })
            }
        )
  }

  toggleModal() {
    this.setState({modalOpen: !this.state.modalOpen})
  }

  setFilters(filters) {
    this.setState({filters: filters})
  }

  changeFilters({target: {name, value}}){
    this.setFilters({...this.state.filters, [name]: value})
  }

  filteredTransactions() {
    const categories = {
      payment: ["check"],
      batch: ["batch"],
      other: ["journal_income", "journal_expense", "nsf_payment", "payment_wo_batch"]
    }
    const {filters} = this.state;
    return Object.values(this.state.transactions).filter(t => {
      if (filters.type && !categories[filters.type].includes(t.type)) return false;
      if (filters.view && !t.reconciled) return false;
      if (filters.min && Math.round(t.amount) < Math.round(filters.min)) return false;
      if (filters.max && Math.round(t.amount) > Math.round(filters.max)) return false;
      if (filters.search && !t.id.toString().includes(filters.search)) return false;
      return true;
    })
  }

  change({target: {name, value}}, data) {
    if (name === "reconciled") value = !data.reconciled;
    this.setState({transactions: {...this.state.transactions, [`${data.type}-${data.id}`]: {...data, [name]: value, changed: true}}})
  }

  toggleModal() {
    this.setState({modalOpen: !this.state.modalOpen})
  }

  changeDates({startDate, endDate}, changed) {
    let promise
    if (changed > 0) {
      promise = confirmation('You will lose all changes unless you press "save for later". proceed ?')
    }
    else {
      promise = new Promise((resolve, reject) => {
        resolve()
      });
    }
    promise.then(() => {
      this.setState({
        filters: {
          ...this.state.filters,
          start_date: startDate.format('YYYY-MM-DD'),
          end_date: endDate.format('YYYY-MM-DD')
        }
      }, () => this.fetchTransactions())
    })
  }

  submit(difference, changed) {
    if (difference != 0) {
      confirmation("difference must be 0 to post.")
    }
    else if (changed > 0){
      confirmation("save changes first.")
    }
     else {
      const posting_id = this.props.match.params.id;
      actions.postReconciliation(posting_id)
      this.props.history.push('/reconcile')
    }
  }

  save() {
    const posting_id = this.props.match.params.id;
    const {transactions} = this.state;
    const changedTransactions = Object.values(transactions).filter(t => !!t.changed);
    setLoading(true)
    actions.save({transactions: changedTransactions, posting_id: this.state.posting_id})
        .finally(() => {
          this.fetchTransactions()
        })
        .finally(() => setLoading(false))
  }

  render() {
    const add = (a, b) => a + b;
    const subtract = (a, b) => a - b;
    const operation = {
      batch: add,
      nsf_payment: subtract,
      check: subtract,
      journal_income: add,
      journal_expense: subtract,
      payment_wo_batch: add
    }
    const {filters, properties, property, clearedTransactions, modalOpen} = this.state;
    const transactions = Object.values(this.state.transactions);
    const {total_deposits, total_payments, start_date, end_date, bank_account_id, posting_id} = this.state;
    const {deposits_in_transit, outstanding_checks, other_items, cleared_checks, cleared_deposits, cleared_other, changed} = transactions.reduce((acc, t) => {
      const amount = parseFloat(t.amount || 0)
      return {
        deposits_in_transit: t.type == "batch" && !t.reconciled ? acc.deposits_in_transit + amount : acc.deposits_in_transit,
        changed: t.changed ? acc.changed + 1: acc.changed,
        outstanding_checks: t.type == "check" && !t.reconciled ? acc.outstanding_checks + amount : acc.outstanding_checks,
        other_items: ["journal_income", "journal_expense", "nsf_payment"].includes(t.type) && !t.reconciled ? operation[t.type](acc.other_items, amount) : acc.other_items,
        cleared_checks: t.type == "check" && t.reconciled ? acc.cleared_checks + amount : acc.cleared_checks,
        cleared_deposits: ["batch"].includes(t.type) && t.reconciled ? acc.cleared_deposits + amount : acc.cleared_deposits,
        cleared_other: ["journal_income", "journal_expense", "nsf_payment", "payment_wo_batch"].includes(t.type) && t.reconciled ? operation[t.type](acc.cleared_other, amount) : acc.cleared_other
      }
    }, {
      deposits_in_transit: 0,
      outstanding_checks: 0,
      other_items: 0,
      cleared_checks: 0,
      cleared_deposits: 0,
      cleared_other: 0,
      changed: 0
    })
    const total = deposits_in_transit - outstanding_checks + other_items;
    const cleared = cleared_deposits - cleared_checks + cleared_other;
    const bank_balance = total_deposits - total_payments;
    const difference = cleared - bank_balance;
    return <Container fluid>
      <Modal isOpen={modalOpen} toggle={this.toggleModal.bind(this)}>
        <ModalBody>
      <EditReconciliation total_payments={total_payments}
                 total_deposits={total_deposits} toggleModal={this.toggleModal.bind(this)} start_date={start_date} end_date={end_date} bank_account_id={bank_account_id} id={posting_id}/>
               </ModalBody>
               </Modal>
                  {changed > 0 && <Row className='d-flex justify-content-center'><Col className='col-auto border rounded'
                                                              style={{position: 'fixed', zIndex: 100, top: 2, left: '55%', backgroundColor: 'gainsboro'}}>Not
            Saved. <Button onClick={this.save.bind(this)} color='link'>Save</Button></Col></Row>
                 }
      <Row className='p-3 m-4'>
        <Col md={4} className='bg-light p-3 border m-2'>
          <Row className='d-flex justify-content-between'>
            <Col>Bank Information</Col>
            <Col>
              <Button color='info' size='sm'
                      onClick={() => this.setState({modalOpen: !this.state.modalOpen})}>Edit
                info</Button>
            </Col></Row>
          <Row className='d-flex'>
            <Col>
              <Row><Col><strong>Total Deposits</strong> : {toCurr(total_deposits)}</Col></Row>
              <Row><Col><strong>Total Withdrawels</strong> : {toCurr(total_payments)}</Col></Row>
              <Row><Col><strong>Start Date</strong> : {moment(start_date).format('MM/DD/YYYY')}</Col></Row>
              <Row><Col><strong>End Date</strong> : {moment(end_date).format('MM/DD/YYYY')}</Col></Row>
            </Col>
            <Col className='p-1'>
              <Row><Col><strong> + Cleared Deposits</strong> : {toCurr(cleared_deposits)}</Col></Row>
              <Row><Col><strong> - Cleared Checks</strong> : {toCurr(cleared_checks)}</Col></Row>
              <Row><Col><strong> +/- Cleared Other</strong> : {toCurr(cleared_other)}</Col></Row>
            </Col>
          </Row>
        </Col>
        <Col md={3} className='bg-light border m-2'>
          <Row>
            <Col>
              <Row className='m-2'><Col>GL Information</Col></Row>
              <Row><Col><strong> + Depoits In Transit</strong> : {toCurr(deposits_in_transit)}</Col></Row>
              <Row><Col><strong> - Outstanding Checks</strong> : {toCurr(outstanding_checks)}</Col></Row>
              <Row><Col><strong> +/- Other Items</strong> : {toCurr(other_items)}</Col></Row>
              <Row><Col><strong>Total</strong> : {toCurr(total)}</Col></Row>
            </Col>
          </Row>
        </Col>
        <Col md={4} style={{padding: 30}}>
          <Row className='d-flex justify-content-between'>
            <Col>
              <Row><Col><small>Bank</small></Col></Row>
              <Row><Col><h5><strong>Net Income</strong> : {toCurr(bank_balance)}</h5></Col></Row>
            </Col>
            <Col>
              <Row><Col><small>Apprent</small></Col></Row>
              <Row><Col><h5><strong>Cleared</strong> : {toCurr(cleared)}</h5></Col></Row>
            </Col>
          </Row>
          <Row>
            <Col className='d-flex mt-3'>
              <h3 className={`${difference == 0 ? 'text-success' : 'text-warning'}`}>Difference
                : {toCurr(difference)}</h3>
            </Col>
          </Row>
        </Col>
      </Row>
      <Row className='d-flex m-4 mt-4 justify-content-center'>
        <Col className='col-auto ml-auto'>
          <ButtonGroup>
            <Button style={{width: '100px'}} name='view' color='dark' value={null} active={!filters.view}
                    onClick={this.changeFilters.bind(this)}
                    outline>All</Button>
            <Button style={{width: '100px'}} name='view' color='dark' value={true} active={!!filters.view}
                    onClick={this.changeFilters.bind(this)} outline>Reconciled </Button>
          </ButtonGroup>
        </Col>
        <Col className='col-auto ml-auto p-1'>
          <Button disabled={changed < 1} color='info' outline style={{borderRadius: '25px'}} className='shadow-sm border' onClick={this.save.bind(this)}>Save for
            later {changed > 0 && <Badge href="#" color="primary" style={{borderRadius: '25px'}}>{changed}</Badge>}</Button>
        </Col>
        <Col className='col-auto p-1'>
          <Button color='success' style={{borderRadius: '25px'}} className='shadow-sm border' onClick={this.submit.bind(this, difference, changed)}>Post <i
              className="fas fa-check"></i></Button>
        </Col>
      </Row>
      <div className='bg-light border rounded'>
        <Row>
          <Col className='p-4'>
            <Row className='d-flex justify-content-between m-3'>
              <Col>
                <ButtonGroup>
                  <Button size='sm' name='type' value={null} active={!filters.type}
                          onClick={this.changeFilters.bind(this)}
                          outline style={{width: 90}}>All</Button>
                  <Button size='sm' name='type' value='payment' active={filters.type === 'payment'}
                          onClick={this.changeFilters.bind(this)} outline style={{width: 90}}>Checks</Button>
                  <Button size='sm' name='type' value='batch' active={filters.type === 'batch'}
                          onClick={this.changeFilters.bind(this)} outline style={{width: 90}}>Deposits</Button>
                  <Button size='sm' name='type' value='other' active={filters.type === 'other'}
                          onClick={this.changeFilters.bind(this)} outline style={{width: 90}}>Other</Button>

                </ButtonGroup>
              </Col>
              <Col md={5}><DateRangePicker startDate={moment(this.state.filters.start_date)}
                                           endDate={moment(this.state.filters.end_date)}
                                           onDatesChange={(value) => this.changeDates(value, changed)}
              />
              </Col>
              <Col>
                <AdvancedFilters onChange={this.setFilters.bind(this)} filters={this.state.filters}/>
              </Col>
            </Row>
            <Row>
              <Col>
                <Pagination component={Transaction}
                            field="data"
                            keyFunc={(t) => `${t.type}-${t.id}`}
                            headers={headers}
                            tableClasses={"table-hover table-sm"}
                            additionalProps={{change: this.change.bind(this)}}
                            collection={this.filteredTransactions()}/>
              </Col>
            </Row>
          </Col>
        </Row>
      </div>
    </Container>
  }

}

export default withRouter(Reconciliation);
