import React from 'react';
import {Row, Col} from "reactstrap";
import moment from "moment";
import {numToLang, prepad, toCurr} from "../../../../../utils";
import DatePicker from "../../../../../components/datePicker";

class CheckDetails extends React.Component {
  render() {
    const {check, account, tenant, onChange} = this.props;
    return <div className="border p-3 mt-3" style={{background: 'whitesmoke'}}>
      <Row className="mb-4">
        <Col style={{lineHeight: '1.2em'}}>
          <h4 className="m-0">{account.name}</h4>
          <div>{account.address.street}</div>
          <div>{account.address.city} {account.address.state} {account.address.zip}</div>
        </Col>
        <Col className="text-center">
          {account.bank_name}
        </Col>
        <Col className="text-center">
          <div>{check.number}</div>
          <div style={{width: 150}} className="m-auto">
            <DatePicker value={check.date} onChange={onChange} name="date"/>
          </div>
        </Col>
      </Row>
      <Row className="mb-2">
        <Col sm={3}>TO THE ORDER OF</Col>
        <Col style={{fontFamily: 'Courier'}}>{tenant.first_name} {tenant.last_name}</Col>
        <Col sm={2} style={{fontFamily: 'Courier'}}>{toCurr(check.amount)}</Col>
      </Row>
      <Row className="mb-3">
        <Col sm={3}/>
        <Col style={{fontFamily: 'Courier'}}>{numToLang(check.amount).toUpperCase()} DOLLARS</Col>
      </Row>
      <Row className="mb-4">
        <Col sm={6}>MEMO &nbsp;&nbsp;&nbsp;Security Deposit Clearing</Col>
        <Col/>
      </Row>
      <Row className="pt-2">
        <Col className="text-center">
          <div className="encoding" style={{fontFamily: 'MICREncoding', fontSize: 25}}>
            c{prepad(check.number)}ca{account.routing_number}a{account.account_number}c
          </div>
        </Col>
      </Row>
      <Row className="mb-3 d-none d-print-block" style={{marginTop: 120}}>
        <Col>
          DATE: {moment(check.date).format('MM/DD/YYYY')} &nbsp;&nbsp;CHK%23:{prepad(check.number)}
          &nbsp;TOTAL:{toCurr(check.amount)} &nbsp;&nbsp;BANK:{check.account} &nbsp;&nbsp;PAYEE:{tenant.name}
        </Col>
      </Row>
    </div>
  }
}

export default CheckDetails;