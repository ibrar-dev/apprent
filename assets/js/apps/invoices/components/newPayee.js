import React from 'react';
import {Button, Popover, PopoverHeader, PopoverBody, Row, Col, Input} from 'reactstrap';
import actions from '../actions';

class NewPayee extends React.Component {
  state = {payee: {address: {}}};

  newPayee() {
    this.setState({...this.state, popoverOpen: !this.state.popoverOpen});
  }

  change({target: {name, value}}) {
    this.setState({...this.state, payee: {...this.state.payee, [name]: value}});
  }

  save() {
    actions.createPayee(this.state.payee).then(this.newPayee.bind(this));
  }

  render() {
    const {popoverOpen, payee} = this.state;
    const change = this.change.bind(this);
    return <React.Fragment>
      <Button style={{backgroundColor:"#3a3b42", color:"white"}} id="newPayeeBtn"
              className="btn-block dropdown-toggle"
              onClick={this.newPayee.bind(this)}>
        New Payee
      </Button>
      <Popover placement="bottom"
               isOpen={popoverOpen}
               target="newPayeeBtn"
               className="popover-max"
               toggle={this.newPayee.bind(this)}>
        <PopoverHeader>New Payee</PopoverHeader>
        <PopoverBody>
          <Row className="mb-2">
            <Col sm={2} className="d-flex align-items-center">Name</Col>
            <Col>
              <Input value={payee.name || ''} name="name" onChange={change}/>
            </Col>
          </Row>
          <Row className="mb-2">
            <Col>
              <Row>
                <Col sm={4} className="d-flex align-items-center">Address</Col>
                <Col>
                  <Input value={payee.street || ''} name="street" onChange={change}/>
                </Col>
              </Row>
            </Col>
            <Col>
              <Row>
                <Col sm={4} className="d-flex align-items-center">City</Col>
                <Col>
                  <Input value={payee.city || ''} name="city" onChange={change}/>
                </Col>
              </Row>
            </Col>
          </Row>
          <Row className="mb-2">
            <Col>
              <Row>
                <Col sm={4} className="d-flex align-items-center">State</Col>
                <Col>
                  <Input value={payee.state || ''} name="state" onChange={change}/>
                </Col>
              </Row>
            </Col>
            <Col>
              <Row>
                <Col sm={4} className="d-flex align-items-center">ZIP</Col>
                <Col>
                  <Input value={payee.zip || ''} name="zip" onChange={change}/>
                </Col>
              </Row>
            </Col>
          </Row>
          <Row>
            <Col className="d-flex justify-content-end">
              <Button color="success" onClick={this.save.bind(this)}>
                Save
              </Button>
            </Col>
          </Row>
        </PopoverBody>
      </Popover>
    </React.Fragment>;
  }
}

export default NewPayee;