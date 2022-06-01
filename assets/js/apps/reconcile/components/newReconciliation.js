import React, {Component} from 'react';
import Select from '../../../components/select';
import {Input, Row, Card, Container, Col, Button, FormGroup, Label, Jumbotron} from 'reactstrap'
import actions from '../actions'
import moment from 'moment'
import DateRangePicker from '../../.././components/dateRangePicker';
import {connect} from 'react-redux';

class NewReconciliation extends Component {
  constructor(props) {
    super(props)
    const {start_date, total_payments, total_deposits, end_date, id} = this.props;
    this.state = {start_date, total_payments, total_deposits, end_date, id}
  }

  change({target: {name, value}}) {
    this.setState({[name]: value})
  }

  createPosting() {
    const {start_date, total_payments, total_deposits, end_date, id} = this.state;
    const {bankId} = this.props;
    const bank_account_id = bankId;
    if (!(start_date && bank_account_id && total_payments && total_deposits && end_date)) {
      return this.setState({invalid: true})
    }
    if (id) {
      actions.updatePosting(id, {start_date, bank_account_id, total_payments, total_deposits, end_date})
          .then(() => actions.setBankId(bank_account_id))
          .finally(() => this.props.toggleModal())
    } else {
      actions.createPosting({start_date, bank_account_id, total_payments, total_deposits, end_date})
          .then(() => actions.setBankId(bank_account_id))
          .then(() => actions.fetchPostings(bank_account_id))
          .finally(() => this.props.toggleModal())
    }
  }

  render() {
    const {start_date, total_payments, total_deposits, end_date, id, invalid} = this.state;
    const {bankAccounts, postings, bankId} = this.props;
    const bank_account_id = bankId;
    const postingsMinusSelf = [...postings];
    const index = postingsMinusSelf.findIndex((p) => p.id == id);
    if (index >= 0) postingsMinusSelf.splice(index, 1)
    return <Container style={{height: '100%'}}>
      <div className='d-flex justify-content-center'>
        <h5 className="display-4">{this.props.id ? '' : 'New Reconciliation'}</h5>
      </div>
      <div style={{margin: '10px', marginTop: '50px', backgroundColor: 'whitesmoke', padding: '50px'}}>
        <Row className='d-flex justify-content-center'>
          <Col style={{zIndex: 5}}>
            <FormGroup>
              <Label>Bank Account</Label>
              <Select
                  options={bankAccounts.map(b => {
                    return {label: `${b.bank_name} - ${b.name}`, value: b.id}
                  })}
                  name='bank_account_id'
                  onChange={this.change.bind(this)}
                  value={bank_account_id}/>
            </FormGroup>
          </Col>
        </Row>
        <Row className='d-flex mt-4'>
          <Col>
            <FormGroup>
              <Label>Total Deposits</Label>
              <Input value={total_deposits} type='number' name='total_deposits' onChange={this.change.bind(this)}/>
            </FormGroup>
          </Col>
          <Col>
            <FormGroup>
              <Label>Total Payments</Label>
              <Input value={total_payments} type='number' name='total_payments' onChange={this.change.bind(this)}/>
            </FormGroup>
          </Col>
        </Row>
        <Row>
          <Col>
            <FormGroup>
              <Label>Date Range</Label>
              <DateRangePicker
                isOutsideRange={(day) => {
                  return postingsMinusSelf.some(p => day.isBetween(moment(p.start_date), moment(p.end_date), 'day', '[]'))
                }}
                  startDate={start_date}
                  endDate={end_date}
                  onDatesChange={({startDate, endDate}) => this.setState({start_date: startDate, end_date: endDate})}
              />
            </FormGroup>
          </Col>
        </Row>
      </div>
      {invalid && <Row className='d-flex justify-content-center'><Col className='col-auto'><small className='text-danger'>All fields are required</small></Col></Row>}
      <Row className='mt-4'>
        <Col className='d-flex justify-content-center'>
          <Button onClick={this.createPosting.bind(this)} color='success'
                  size='lg'>{this.props.id ? 'Update' : 'Create'}</Button>
        </Col>
      </Row>
    </Container>;
  }

}

export default connect(({postings, bankAccounts, bankId}) => {
  return {postings, bankAccounts, bankId}
})(NewReconciliation);
