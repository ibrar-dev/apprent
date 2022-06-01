import React, {Component} from 'react';
import {Row, Col, Button, Card, CardBody, Label, Input, ButtonGroup} from 'reactstrap'

const labels = {
  epremium: 'ePremium Account Number',
  bond: 'Set Bond Amount',
  deposit: 'Set Deposit Amount'
};

class SecurityDeposit extends Component {
  change({target: {name, value}}) {
    this.props.onChange(name, value);
  }

  setDepositType(type) {
    this.props.onChange('deposit_type', type);
  }

  render() {
    const {lease} = this.props;
    return <div>
      <h3>Security Deposit & Keys</h3>
      <Row>
        <Col md={8}>
          <Card>
            <CardBody>
              <ButtonGroup>
                <Button onClick={this.setDepositType.bind(this, "deposit")} active={lease.deposit_type === "deposit"}
                        color="info" disabled={lease.locked}>Deposit</Button>
                <Button onClick={this.setDepositType.bind(this, "bond")} active={lease.deposit_type === "bond"}
                        color="info" disabled={lease.locked}>Bond</Button>
                <Button onClick={this.setDepositType.bind(this, "epremium")} active={lease.deposit_type === "epremium"}
                        color="info" disabled={lease.locked}>ePremium</Button>
              </ButtonGroup>
              <hr/>
              <div>
                <div className='form-group'>
                  <Label>{labels[lease.deposit_type]}</Label>
                  <Input value={lease.deposit_value || ''} name="deposit_value"
                         disabled={lease.locked} onChange={this.change.bind(this)}/>
                  {lease.deposit_type === 'deposit' &&
                  <small>Note that the deposit will be stored in the standard bank account.</small>}
                </div>
              </div>
            </CardBody>
          </Card>
        </Col>
        <Col md={4}>
          <Card>
            <CardBody>
              <div className='form-group'>
                <Label>Unit Key</Label>
                <Input value={lease.unit_keys} type="number" name="unit_keys"
                       disabled={lease.locked} onChange={this.change.bind(this)}/>
              </div>
              <div className='form-group'>
                <Label>Mail Key</Label>
                <Input value={lease.mail_keys} type="number" name="mail_keys"
                       disabled={lease.locked} onChange={this.change.bind(this)}/>
              </div>
              <div className='form-group'>
                <Label>Other Key</Label>
                <Input value={lease.other_keys} type="number" name="other_keys"
                       disabled={lease.locked} onChange={this.change.bind(this)}/>
              </div>
            </CardBody>
          </Card>
        </Col>
      </Row>
    </div>;
  }
}

export default SecurityDeposit;