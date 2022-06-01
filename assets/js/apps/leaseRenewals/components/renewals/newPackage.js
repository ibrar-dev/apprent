import React, {Component} from 'react';
import {Row, Col, Input} from 'reactstrap';

class NewPackage extends Component {
  state = {};

  render() {
    const {params: {min, max, base, amount, dollar}, change, remove, index} = this.props;
    return <Row className="d-flex justify-content-between align-items-center mt-2">
      <div className="pl-2">
        <i className="fas fa-trash text-danger" style={{cursor: 'pointer'}} onClick={remove} />
      </div>
      <Col className="pr-0">
        <span>Package {index + 1}</span>
      </Col>
      <Col className="pr-0">
        <Input name="min" type="number" value={min || ''} onChange={change} />
      </Col>
      <Col className="pr-0">
        <Input name="max" type="number" value={max || ''} onChange={change} />
      </Col>
      <Col className="pr-0">
        <Input name="amount" type="number" value={amount || ''} onChange={change} />
      </Col>
      <Col className="pr-0">
        <Input type="select" value={dollar ? '1' : '0'} name="dollar" onChange={change}>
          <option value="1">$ (Dollar)</option>
          <option value="0">% (Percentage)</option>
        </Input>
      </Col>
      <Col>
        <Input type="select" value={base || ''} onChange={change} name="base">
          <option value="Market Rent">Market Rent</option>
          <option value="Current Rent">Current Rent</option>
        </Input>
      </Col>
    </Row>
  }
}

export default NewPackage;