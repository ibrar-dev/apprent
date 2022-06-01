import React from 'react';
import {Row, Col, Card, CardBody, Input, Label} from "reactstrap";
import moment from 'moment';
import Select from '../../../../../components/select';

const currentYear = (new Date()).getFullYear();
const monthOptions = moment.months().map((m) => {
  return {label: m, value: m};
});
const yearOptions = [...Array(10)].map((n, i) => {
  return {value: currentYear + i, label: currentYear + i};
});

class Concessions extends React.Component {
  state = {};

  change({target: {name, value}}) {
    this.props.onChange(name, value);
  }

  changeConc({target: {name, value}}) {
    this.setState({[name]: value});
  }

  addMonth() {
    const {concMonth, concYear} = this.state;
    const {lease: {concession_months}, onChange} = this.props;
    const newMonth = `${concMonth} ${concYear}`;
    if (!concession_months.includes(newMonth)) concession_months.push(newMonth);
    onChange('concession_months', concession_months);
  }

  removeMonth(i) {
    const {lease: {concession_months}, onChange} = this.props;
    concession_months.splice(i, 1);
    onChange('concession_months', concession_months);
  }

  render() {
    const {lease} = this.props;
    const {concMonth, concYear} = this.state;
    return <div>
      <h3>Concessions & Discounts</h3>
      <Card>
        <CardBody>
          <div className="d-flex align-items-center mb-4">
            <Label className="nowrap mr-2 mb-0">Buy Out Fee</Label>
            <Input value={lease.buy_out_fee || ''} type="number" name="buy_out_fee"
                   disabled={lease.locked} onChange={this.change.bind(this)}/>
          </div>
          <div className="d-flex align-items-center">
            <Label className="nowrap mr-2 mb-0">Total Concession Amount</Label>
            <Input value={lease.concession_fee || ''} type="number" name="concession_fee"
                   disabled={lease.locked} onChange={this.change.bind(this)}/>
          </div>
        </CardBody>
      </Card>
      <Card>
        <CardBody>
          <div className="d-flex mb-4">
            <Label className="nowrap mr-2 mt-2 mb-0">One-Time Concession</Label>
            <Row className="w-100">
              <Col md={4}>
                <Input value={lease.one_time_concession || ''} type="number" name="one_time_concession"
                       disabled={lease.locked} onChange={this.change.bind(this)}/>
                <small>
                  <ul className="list-unstyled" style={{minWidth: 130}}>
                    {lease.concession_months.map((m, i) => {
                      return <li className="nowrap p-1 bg-light border d-inline-block" key={m}>
                        <a onClick={this.removeMonth.bind(this, i)}><i className="fas fa-times text-danger"/></a> {m}
                      </li>;
                    })}
                  </ul>
                </small>
              </Col>
              <Col>
                <div className="d-flex align-items-center">
                  <Label className="nowrap mr-2 mb-0">For Months:</Label>
                  <div className="d-flex w-100">
                    <div className="w-50">
                      <Select value={concMonth} name="concMonth" options={monthOptions}
                              disabled={lease.locked} onChange={this.changeConc.bind(this)}/>
                    </div>
                    <div className="w-50 ml-2">
                      <Select value={concYear} name="concYear" options={yearOptions}
                              disabled={lease.locked} onChange={this.changeConc.bind(this)}/>
                    </div>
                  </div>
                  <button className="btn p-0 ml-2 btn-white" onClick={this.addMonth.bind(this)}
                          disabled={!concMonth || !concYear}>
                    <i className="fas fa-plus-circle text-success fa-2x"/>
                  </button>
                </div>
              </Col>
            </Row>
          </div>
          <div className="d-flex align-items-center mb-4">
            <Label className="nowrap mr-2 mb-0">Monthly Discount</Label>
            <Input value={lease.monthly_discount || ''} type="number" name="monthly_discount"
                   disabled={lease.locked} onChange={this.change.bind(this)}/>
          </div>
          <div className="d-flex align-items-center">
            <Label className="nowrap mr-2 mb-0">Other Discount</Label>
            <Input type="textarea" value={lease.other_discount || ''} name="other_discount" rows={4}
                   disabled={lease.locked} onChange={this.change.bind(this)}/>
          </div>
        </CardBody>
      </Card>
    </div>;
  }
}

export default Concessions;