import React from 'react';
import {Row, Col} from "reactstrap";
import {numToLang, prepad, toCurr} from "../../../../utils";

class CheckDetails extends React.Component {
  render() {
    const {amount, number, name, property, memo} = this.props;
    return <div className="border p-3 mt-3" style={{background: 'whitesmoke'}}>
      <Row className="mb-4">
        <Col style={{lineHeight: '1.2em'}}>
          <h4 className="m-0">{name}</h4>
          <div>123 Sesame St</div>
          <div>Somewhere, GG 12345</div>
        </Col>
        <Col className="text-center">
          Acme Bank
        </Col>
        <Col className="text-center">
          <div>{number}</div>
          <div style={{width: 150}} className="m-auto">
            1/1/2000
          </div>
        </Col>
      </Row>
      <Row className="mb-2">
        <Col sm={3}>TO THE ORDER OF</Col>
        <Col style={{fontFamily: 'Courier'}}>{property}</Col>
        <Col sm={2} style={{fontFamily: 'Courier'}}>{amount && toCurr(amount)}</Col>
      </Row>
      <Row className="mb-3">
        <Col sm={3}/>
        <Col style={{fontFamily: 'Courier'}}>{amount && numToLang(amount).toUpperCase()} DOLLARS</Col>
      </Row>
      <Row className="mb-4">
        <Col sm={6}>MEMO &nbsp;&nbsp;&nbsp;{memo}</Col>
        <Col/>
      </Row>
      <Row className="pt-2">
        <Col className="text-center">
          <div className="encoding" style={{fontFamily: 'MICREncoding', fontSize: 25}}>
            c{number ? prepad(number, 12) : '0000000'}ca{123456789}a{111222333}c
          </div>
        </Col>
      </Row>
    </div>
  }
}

export default CheckDetails;