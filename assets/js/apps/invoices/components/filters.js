import React from 'react';
import {Popover, PopoverBody, PopoverHeader, Button, Input, Row, Col, Container, ButtonGroup} from 'reactstrap';
import Select from '../../../components/select';
import DatePicker from '../../../components/datePicker';
import {connect} from 'react-redux';
import actions from '../actions'
import moment from 'moment'

class Filters extends React.Component {
  state = {open: false};

  toggle() {
    this.setState({open: !this.state.open})
  }

  postMonths() {
    let months = [];
    let limit = 12;
    Array.apply(null, Array(limit)).forEach((_a, i) => {
      const value = moment().subtract(limit - i, 'months').date(1);
      months.push({label: value.format('MMMM YYYY'), value: value.format('YYYY-MM-DD')})
    });
    Array.apply(null, Array(limit + 1)).forEach((_a, i) => {
      const value = moment().add(i, 'months').date(1);
      months.push({label: value.format('MMMM YYYY'), value: value.format('YYYY-MM-DD')})
    });
    return months;
  }

  render() {
    const {bankAccounts, payees, additionalFilters, filters, properties, change, accounts} = this.props;
    const {open} = this.state;
    const numFilters = Object.keys(filters).length + Object.keys(additionalFilters).length;
    return <div>
      <Button color='light' style={{borderColor: `${numFilters > 0 ? 'orange' : 'lightgrey'}`}}
              onClick={this.toggle.bind(this)} id="advanced-filters">
        {numFilters > 0 ? `${numFilters} Active Filters` : 'Filters'} <i className="fas fa-filter"/>
      </Button>
      <Popover placement="bottom" isOpen={open} target="advanced-filters" className="popover-max"
               toggle={this.toggle.bind(this)}>
        <PopoverHeader>Filters</PopoverHeader>
        <PopoverBody style={{minWidth: 500}}>
          <Container style={{paddingTop: 10, paddingBottom: 10}}>
            <Row className="mt-2 mb-3">
              <Col>
                <ButtonGroup>
                  <Button outline onClick={() => change({target: {name: 'openInvoices', value: ''}})}
                          active={!additionalFilters.openInvoices} color='dark'>All</Button>
                  <Button outline onClick={() => change({target: {name: 'openInvoices', value: 'true'}})}
                          active={additionalFilters.openInvoices} color='dark'>Open Invoices</Button>
                </ButtonGroup>
              </Col>
            </Row>
            <div className="mt-2 mb-3">
              <div className="labeled-box">
              <Input value={filters.number || ''} name="number" onChange={actions.setFilter.bind(null, 'number')}/>
                <div className="labeled-box-label">Invoice Number</div>
              </div>
            </div>
            <Row className="mt-2 mb-3">
              <Col>
                <div className="labeled-box">
                  <Select value={filters.payee_id}
                          isClearable={true}
                          options={payees.map(p => {
                            return {label: p.name, value: p.id};
                          })}
                          onChange={actions.setFilter.bind(null, 'payee_id')}/>
                  <div className="labeled-box-label">Payee</div>
                </div>
              </Col>
              <Col>
                <div className="labeled-box">
                  <Select value={additionalFilters.bank_id}
                          name="bank_id"
                          isClearable={true}
                          options={bankAccounts.map(a => {
                            return {label: a.bank_name, value: a.id};
                          })}
                          onChange={change}/>
                  <div className="labeled-box-label">Bank</div>
                </div>
              </Col>
            </Row>
            <Row className="mt-2 mb-3">
              <Col>
                <div className="labeled-box">
                  <Select value={filters.property_id}
                          isClearable={true}
                          options={properties.map(p => {
                            return {label: p.name, value: p.id};
                          })}
                          onChange={actions.setFilter.bind(null, 'property_id')}/>
                  <div className="labeled-box-label">Property</div>
                </div>
              </Col>
              <Col>
                <div className="labeled-box">
                  <Select value={additionalFilters.account_id}
                          name="account_id"
                          isClearable={true}
                          options={accounts.filter(a => a.is_payable).map(a => {
                            return {label: a.name, value: a.id};
                          })}
                          onChange={change}/>
                  <div className="labeled-box-label">Payable Account</div>
                </div>
              </Col>
            </Row>
            <Row className="mt-2 mb-3">
              <Col>
                <div className="labeled-box">
                  <Select onChange={change}
                          value={additionalFilters.post_month}
                          name="post_month"
                          isClearable={true}
                          options={this.postMonths()}/>
                  <div className="labeled-box-label">Post Month</div>
                </div>
              </Col>
              <Col>
                <div className="labeled-box">
                  <Input type="textarea" name="notes"
                         value={additionalFilters.notes || ""} onChange={change}/>
                  <div className="labeled-box-label">Notes</div>
                </div>
                {additionalFilters.notes && <a style={{position: 'absolute', bottom: '75%', left: '88%'}}
                                               onClick={() => change({target: {name: "notes", value: ""}})}
                                               className="fas fa-times"/>}
              </Col>
            </Row>
            <Row className="mt-2 mb-3">
              <Col>
                <div className="labeled-box">
                  <DatePicker clearable name="due_date"
                              value={filters.due_date_start}
                              onChange={actions.setFilter.bind(null, 'due_date_start')}/>
                  <div className="labeled-box-label">Due Date Start</div>
                </div>
              </Col>
              <Col>
                <div className="labeled-box">
                  <DatePicker clearable name="due_date" value={filters.due_date_end}
                              onChange={actions.setFilter.bind(null, 'due_date_end')}/>
                  <div className="labeled-box-label">Due Date End</div>
                </div>
              </Col>
            </Row>
          </Container>
        </PopoverBody>
      </Popover>
    </div>;
  }
}

export default connect(({accounts, bankAccounts, payees, filters, properties}) => {
  return {accounts, bankAccounts, payees, filters, properties}
})(Filters);
