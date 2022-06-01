import React from 'react';
import {Row, Col} from "reactstrap";
import moment from "moment";
import {numToLang, prepad, toCurr} from "../../../utils";

class CheckDetails extends React.Component {
  render() {
    const {check} = this.props;
    const account = check.bank_account;
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
          <div>{moment(check.date).format('MM/DD/YYYY')}</div>
        </Col>
      </Row>
      <Row className="mb-2">
        <Col sm={3}>TO THE ORDER OF</Col>
        <Col style={{fontFamily: 'Courier'}}>{check.payee}</Col>
        <Col sm={2} style={{fontFamily: 'Courier'}}>{toCurr(check.amount)}</Col>
      </Row>
      <Row className="mb-3">
        <Col sm={3}/>
        <Col style={{fontFamily: 'Courier'}}>{numToLang(check.amount).toUpperCase()} DOLLARS</Col>
      </Row>
      <Row className="mb-4">
        <Col sm={6}>MEMO &nbsp;&nbsp;&nbsp;</Col>
        <Col/>
      </Row>
      <Row className="pt-2">
        <Col className="text-center">
          <div className="encoding" style={{fontFamily: 'MICREncoding', fontSize: 25}}>
            c{prepad(check.number)}ca{account.routing_number}a{account.account_number}c
          </div>
        </Col>
      </Row>
    </div>
  }
}

export default CheckDetails;