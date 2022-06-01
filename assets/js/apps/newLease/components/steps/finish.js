import React, {Component} from 'react';
import {Row, Col, Card, CardBody, ListGroup, ListGroupItem, Button} from 'reactstrap';
import moment from 'moment';
import actions from '../../actions';
import confirmation from '../../../../components/confirmationModal';
import {toCurr} from '../../../../utils';
import {connect} from 'react-redux';

const depositValues = {
  epremium: 'ePremium Account Number',
  bond: 'Bond Amount',
  deposit: 'Deposit Amount'
};

const bugs = [
  '',
  'has inspected the dwelling prior to move-in',
  'will inspect the dwelling within 48 hours after move-in',
];

class Finish extends Component {
  requestSignatures() {
    const {lease, rent} = this.props;
    lease.rent = rent;
    if (rent <= 0) {
      alert('Please enter a rent amount greater than zero');
      return
    }
    confirmation('Please confirm that you are finished setting up the lease. Confirming will email the resident(s) requesting their signature.').then(() => {
      actions.submitForSignature(lease);
    })
  }

  render() {
    const {lease, rent} = this.props;
    return <Card>
      <CardBody>
        <h3 className="mb-1">Lease Date: {moment(lease.lease_date).format("MM/DD/YYYY")}</h3>
        <h5 className="mb-1">Lease Start: {moment(lease.start_date).format("MM/DD/YYYY")}</h5>
        <h5 className="mb-4">Lease End: {moment(lease.end_date).format("MM/DD/YYYY")}</h5>
        <h5 className="mb-4">Rent: {toCurr(rent)}</h5>
        <h5>Persons</h5>
        <ListGroup className="mb-3">
          {lease.residents.map(p => <ListGroupItem key={p}>{p}: Lease Holder</ListGroupItem>)}
          {lease.occupants.map(p => <ListGroupItem key={p}>{p}: Occupant</ListGroupItem>)}
        </ListGroup>
        <Row className="mb-3">
          <Col>
            <h5>{depositValues[lease.deposit_type]}</h5>
            <div>{lease.deposit_type === 'epremium' ? lease.deposit_value : toCurr(lease.deposit_value)}</div>
          </Col>
          <Col>
            <h5>Unit Key</h5>
            <div>{lease.unit_keys}</div>
          </Col>
          <Col>
            <h5>Mail Key</h5>
            <div>{lease.mail_keys}</div>
          </Col>
          <Col>
            <h5>Other Key</h5>
            <div>{lease.other_keys}</div>
          </Col>
        </Row>
        <h5>Bed Bugs</h5>
        <div style={{marginBottom: -6}}>{bugs[lease.bug_inspection]}</div>
        <small>Unit {lease.bug_inspected ? 'has been' : 'will be'} inspected for bed bugs</small>
        <h5 className="mt-3">Concessions & Discounts</h5>
        <div>{lease.buy_out_fee && `Buy Out Fee: ${toCurr(lease.buy_out_fee)}`}</div>
        <div>{lease.concession_fee && `Total Concession Fee: ${toCurr(lease.concession_fee)}`}</div>
        <div>
          {lease.one_time_concession && `One-Time Concession: ${toCurr(lease.one_time_concession)} for: `}
          {lease.concession_months.join(', ')}
        </div>
        <div>{lease.monthly_discount && `Monthly Concession: ${toCurr(lease.monthly_discount)}`}</div>
        <div>{lease.other_discount && `Other Discount: ${lease.other_discount}`}</div>
        <h5 className="mt-3">Gate Access</h5>
        <Row>
          <Col sm={3}>
            <ul>
              {lease.gate_access_remote && <li>Remote Access</li>}
              {lease.gate_access_card && <li>Card Access</li>}
              {lease.gate_access_code && <li>Code Access</li>}
            </ul>
          </Col>
          <Col>
            <ul>
              {lease.lost_remote_fee && <li>Lost Remote Fee</li>}
              {lease.lost_card_fee && <li>Lost Card Fee</li>}
              {lease.code_change_fee && <li>Code Change Fee</li>}
            </ul>
          </Col>
        </Row>
        <h5>Washer Dryer Addendum</h5>
        <ul>
          {lease.washer_rent && <li>Monthly Rent: {toCurr(lease.washer_rent)}</li>}
          {lease.washer_type && <li>Type: {lease.washer_type}</li>}
          {(lease.washer_serial || lease.dryer_serial) && <li>
            <b>Washer Serial:</b> {lease.washer_serial}<br/><b>Dryer Serial:</b> {lease.dryer_serial}
          </li>}
        </ul>
        <h5 className="mt-3">Other Items</h5>
        <div>Fitness Center card numbers: {lease.fitness_card_numbers.join(', ')}</div>
        <div>Smart Unit Fee: {lease.smart_fee && toCurr(lease.smart_fee)}</div>
        <div>Regal Waste Fee: {lease.waste_cost && toCurr(lease.waste_cost)}</div>
        <div>Renter's Insurance Co: {lease.insurance_company && lease.insurance_company}</div>
        <Row className="mt-3">
          <Col sm={{size: 6, offset: 3}}>
            <Button block size="lg" color="success" onClick={this.requestSignatures.bind(this)}>
              Ready for Signature
            </Button>
          </Col>
        </Row>
      </CardBody>
    </Card>;
  }
}


export default connect(({rent}) => {
  return {rent};
})(Finish);
