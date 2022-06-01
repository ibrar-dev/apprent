import React from 'react';
import {connect} from 'react-redux';
import {Row, Col} from 'reactstrap';
import Checks from './checks';
import actions from '../actions';
import Select from '../../../components/select';
import DatePicker from '../../../components/datePicker';

class ChecksApp extends React.Component {
  render() {
    const {payees, filters, bankAccounts} = this.props;
    return <div>
      <Row style={{paddingTop: 10, paddingBottom: 10}}>
        <Col>
          <Select value={filters.payee_id} isClearable={true}
                  placeholder="Payee"
                  options={payees.map(p => {
                    return {label: p.name, value: p.id};
                  })}
                  onChange={actions.setFilter.bind(null, 'payee_id')}/>
        </Col>
        <Col>
          <Select value={filters.account_id} isClearable={true}
                  placeholder={"Bank Account"}
                  options={bankAccounts.map(a => {
                    return {label: a.name, value: a.id};
                  })}
                  onChange={actions.setFilter.bind(null, 'account_id')}/>
        </Col>
        <Col>
          <Row>
            <Col>
              <DatePicker name="due_date" placeholder="Start" value={filters.date_start} clearable
                          onChange={actions.setFilter.bind(null, 'date_start')}/>
            </Col>
            <Col>
              <DatePicker name="due_date" placeholder="End" value={filters.date_end} clearable
                          onChange={actions.setFilter.bind(null, 'date_end')}/>
            </Col>
          </Row>
        </Col>
      </Row>
      <Checks/>
    </div>
  }
}

export default connect(({filter, payees, filters, accounts, bankAccounts, properties}) => {
  return {filter, payees, filters, accounts, bankAccounts, properties};
})(ChecksApp);