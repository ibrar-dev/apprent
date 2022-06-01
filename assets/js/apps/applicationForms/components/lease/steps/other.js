import React from 'react';
import {Input, Card, CardBody, Label, Row, Col} from "reactstrap";

const fitnessCardNumbers = 4;

class Other extends React.Component {
  change({target: {name, value}}) {
    this.props.onChange(name, value);
  }

  changeFitnessCardNumber(index, {target: {value}}) {
    const {lease: {fitness_card_numbers}, onChange} = this.props;
    fitness_card_numbers[index] = value;
    onChange('fitness_card_numbers', fitness_card_numbers);
  }

  render() {
    const {lease} = this.props;
    return <div>
      <h3>Other Items</h3>
      <Card>
        <CardBody>
          <div className="d-flex align-items-center mb-4">
            <Label className="nowrap mr-2 mb-0">Fitness Center card numbers</Label>
            <Row className="w-100">
              {[...Array(fitnessCardNumbers)].map((v, index) => {
                return <Col key={index}>
                  <Input value={lease.fitness_card_numbers[index] || ''} disabled={lease.locked}
                         onChange={this.changeFitnessCardNumber.bind(this, index)}/>
                </Col>;
              })}
            </Row>
          </div>
          <div className="d-flex align-items-center mb-4">
            <Label className="nowrap mr-2 mb-0">Smart Unit Fee</Label>
            <Input value={lease.smart_fee || ''} type="number" name="smart_fee"
                   disabled={lease.locked} onChange={this.change.bind(this)}/>
          </div>
          <div className="d-flex align-items-center mb-4">
            <Label className="nowrap mr-2 mb-0">Regal Waste Fee</Label>
            <Input value={lease.waste_cost || ''} type="number" name="waste_cost"
                   disabled={lease.locked} onChange={this.change.bind(this)}/>
          </div>
          <div className="d-flex align-items-center">
            <Label className="nowrap mr-2 mb-0">Renter's Insurance Provider</Label>
            <Input value={lease.insurance_company || ''} name="insurance_company"
                   disabled={lease.locked} onChange={this.change.bind(this)}/>
          </div>
        </CardBody>
      </Card>
    </div>;
  }
}

export default Other;