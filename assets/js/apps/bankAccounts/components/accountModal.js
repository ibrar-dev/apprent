import React from 'react';
import {connect} from 'react-redux';
import {Modal, ModalHeader, ModalBody, ModalFooter, Input, InputGroup} from 'reactstrap';
import {Row, Col, InputGroupAddon, Button} from 'reactstrap';
import Select from '../../../components/select';
import actions from '../actions';

function validateRouting(number) {
  if (!number || number.length !== 9 || number.charAt(0) === '5') return false;
  //First two digits are between 01-12, 21-32, 61-72, 80
  const validStart = number.substring(0, 2);
  const regexp = /0(?=[1-9])|1(?=[0-2])|2(?=[0-9])|3(?=[0-2])|6(?=[0-9])|7(?=[0-2])|80/;
  if (!validStart.match(regexp)) return false;
  //ABA Routing Number Checksum
  let n = 0;
  for (let i = 0; i < number.length; i += 3) {
    n += parseInt(number.charAt(i), 10) * 3
      + parseInt(number.charAt(i + 1), 10) * 7 + parseInt(number.charAt(i + 2), 10);
  }
  return !(n === 0 || n % 10 !== 0);
}

class AccountModal extends React.Component {
  state = {account: this.props.account};

  change({target: {name, value}}) {
    this.setState({...this.state, account: {...this.state.account, [name]: value}});
  }

  changeAddress({target: {name, value}}) {
    this.setState({
      ...this.state,
      account: {...this.state.account, address: {...this.state.account.address, [name]: value}}
    });
  }

  save() {
    actions.saveBankAccount(this.state.account).then(this.props.toggle);
  }

  render() {
    const {toggle, properties, accounts} = this.props;
    const {account} = this.state;
    const valid = validateRouting(account.routing_number);
    const change = this.change.bind(this);
    const changeAddress = this.changeAddress.bind(this);
    return <Modal toggle={toggle} isOpen={true} size="lg">
      <ModalHeader toggle={toggle}>
        {account.id ? 'Edit' : 'New'} Bank Account
      </ModalHeader>
      <ModalBody>
        <Row className="mb-3">
          <Col>
            <Row>
              <Col sm={2} className="d-flex align-items-center">
                Properties
              </Col>
              <Col>
                <Select value={account.property_ids}
                        multi={true}
                        closeMenuOnSelect={false}
                        onChange={change}
                        options={properties.map(p => {
                          return {label: p.name, value: p.id};
                        })}
                        name="property_ids"/>
              </Col>
            </Row>
          </Col>
        </Row>
        <Row className="mb-3">
          <Col>
            <Row>
              <Col sm={2} className="d-flex align-items-center">
                Account
              </Col>
              <Col>
                <Select value={account.account_id}
                        onChange={change}
                        options={accounts.map(a => {
                          return {label: a.name, value: a.id};
                        })}
                        name="account_id"/>
              </Col>
            </Row>
          </Col>
        </Row>
        <Row className="mb-3">
          <Col>
            <Row>
              <Col sm={4} className="d-flex align-items-center">
                Name
              </Col>
              <Col>
                <Input value={account.name || ''} onChange={change} name="name"/>
              </Col>
            </Row>
          </Col>
          <Col>
            <Row>
              <Col sm={4} className="d-flex align-items-center">
                Bank Name
              </Col>
              <Col>
                <Input value={account.bank_name || ''} onChange={change} name="bank_name"/>
              </Col>
            </Row>
          </Col>
        </Row>
        <Row className="mb-3">
          <Col>
            <Row>
              <Col sm={4} className="d-flex align-items-center">
                Account #
              </Col>
              <Col>
                <Input value={account.account_number || ''} onChange={change} name="account_number"/>
              </Col>
            </Row>
          </Col>
          <Col>
            <Row>
              <Col sm={4} className="d-flex align-items-center">
                Routing #
              </Col>
              <Col>
                <InputGroup>
                  <Input value={account.routing_number || ''}
                         onChange={change} name="routing_number"/>
                  <InputGroupAddon addonType="append">
                    <Button color={valid ? 'success' : 'danger'}>
                      <i className={`fas fa-${valid ? 'check' : 'times'}`}/>
                    </Button>
                  </InputGroupAddon>
                </InputGroup>
              </Col>
            </Row>
          </Col>
        </Row>
        <Row className="mb-3">
          <Col>
            <Row>
              <Col sm={4} className="d-flex align-items-center">
                Street
              </Col>
              <Col>
                <Input value={account.address.street || ''} onChange={changeAddress} name="street"/>
              </Col>
            </Row>
          </Col>
          <Col>
            <Row>
              <Col sm={4} className="d-flex align-items-center">
                City
              </Col>
              <Col>
                <Input value={account.address.city || ''} onChange={changeAddress} name="city"/>
              </Col>
            </Row>
          </Col>
        </Row>
        <Row className="mb-3">
          <Col>
            <Row>
              <Col sm={4} className="d-flex align-items-center">
                State
              </Col>
              <Col>
                <Select value={account.address.state || ''}
                        onChange={changeAddress}
                        options={USSTATES}
                        name="state"/>
              </Col>
            </Row>
          </Col>
          <Col>
            <Row>
              <Col sm={4} className="d-flex align-items-center">
                ZIP
              </Col>
              <Col>
                <Input value={account.address.zip || ''} onChange={changeAddress} name="zip"/>
              </Col>
            </Row>
          </Col>
        </Row>
      </ModalBody>
      <ModalFooter>
        <Button color="danger" onClick={toggle}>
          Cancel
        </Button>
        <Button color="success" onClick={this.save.bind(this)}>
          Save
        </Button>
      </ModalFooter>
    </Modal>;
  }
}

export default connect(({properties, accounts}) => {
  return {properties, accounts};
})(AccountModal);