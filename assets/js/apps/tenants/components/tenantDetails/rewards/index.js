import React from 'react';
import {Card, CardBody, Button, CardHeader, Col, Row, Modal, ModalHeader, ModalBody, ModalFooter} from 'reactstrap';
import {Input, Container, ListGroup, ListGroupItem} from 'reactstrap';
import Select from '../../../../../components/select';
import Pagination from '../../../../../components/simplePagination/index'
import actions from "../../../actions";
import {connect} from "react-redux";
import Award from './award';
import Purchase from './purchase';

class Index extends React.Component {
  state = {awardModal: false, prizeModal: false, reason: '', amount: '', type: [], prizeId: ""};

  //THIS SEEMS STUPID TO GET ALL THE DATA IN 5 DIFFERENT CALLS
  componentWillMount() {
    const {tenant_id: id} = this.props.tenant;
    actions.getTenantAwardHistory(id);
    actions.getTenantPurchaseHistory(id);
    actions.getTenantPoints(id);
    actions.getAwardTypes();
    actions.getPrizes();
  }

  _filters() {

  }

  change(e) {
    this.setState({...this.state, [e.target.name]: e.target.value});
  }

  headers = {
    columns: [
      {label: 'Amount', min: true},
      {label: 'Reason', sort: 'name'},
      {label: 'Created By', sort: 'num'},
      {label: 'Date Awarded'}
    ], style: {color: '#7d7d7d'}
  };

  purchaseHeaders = {
    columns: [
      {label: 'Amount', min: true},
      {label: 'Prize', sort: 'name'},
      {label: 'Date Purchased'},
      {label: 'Status'}
    ], style: {color: '#7d7d7d'}
  };

  awardModal() {
    this.setState({...this.state, awardModal: !this.state.awardModal});
  }

  prizeModal() {
    this.setState({...this.state, prizeModal: !this.state.prizeModal});
  }

  changeType(type) {
    this.setState({...this.state, type: type.target});
  }

  addAward() {
    const award = {
      tenant_id: this.props.tenant.id,
      reason: this.state.reason,
      amount: this.state.amount,
      type_id: this.state.type.value
    };
    actions.addAward(award, this.props.tenant.id);
    this.setState({...this.state, awardModal: !this.state.awardModal});
  }

  redeem() {
    const award = {
      tenant_id: this.props.tenant.tenant_id,
      reason: this.state.reason,
      amount: this.state.amount,
      type_id: this.state.type.value
    };
    actions.addAward(award, this.props.tenant.id)
    this.setState({...this.state, awardModal: !this.state.awardModal});
  }

  prizeSelected(p) {
    this.setState({...this.state, prizeId: p})
  }

  purchasePrize() {
    const {tenant_id: id} = this.props.tenant;
    const {prizeId, prizeModal} = this.state;
    const purchase = {tenant_id: id, reward_id: prizeId};
    actions.purchasePrize(purchase, id);
    this.setState({prizeModal: !prizeModal});
  }

  render() {
    const {rewards, awardTypes, purchaseHistory, prizes, points} = this.props;
    const {reason, amount, type, prizeId} = this.state;
    const typeOptions = awardTypes.types ? awardTypes.types.map(type => {
      return {value: type.id, label: type.name}
    }) : [];
    return <div className="px-4">
      <Card>
        <CardHeader>Rewards</CardHeader>
        <CardBody className="p-0">
          <div style={{}} className="d-flex justify-content-center">
            <div style={{width: "80%", margin: '40px'}} className="d-flex justify-content-between">
              <h1 style={{color: '#465e77'}}>Total Points: {points}</h1>
              <div className="d-flex flex-col">
                <Button color="success" style={{width: 150}} onClick={this.awardModal.bind(this)}> Add Points</Button>
                <Button color="success" style={{width: 150, marginLeft: 10}}
                        onClick={this.prizeModal.bind(this)}> Redeem Prize</Button>
              </div>
            </div>
          </div>
          <Container>
            <div className="row">
              <div className="col-6">
                <Card>
                  <Pagination
                    title="Awards"
                    collection={rewards.awards ? rewards.awards : []}
                    component={Award}
                    headers={this.headers}
                    filters={this._filters()}
                    field="award"
                    hover={true}
                  />
                </Card>
              </div>
              <div className="col-6">
                <Card>
                  <Pagination
                    title="Purchase History"
                    collection={purchaseHistory.purchases ? purchaseHistory.purchases : []}
                    component={Purchase}
                    headers={this.purchaseHeaders}
                    filters={this._filters()}
                    field="purchase"
                    hover={true}
                  />
                </Card>
              </div>
            </div>
          </Container>
        </CardBody>
        <Modal isOpen={this.state.awardModal} toggle={this.awardModal.bind(this)}>
          <ModalHeader toggle={this.awardModal.bind(this)}>Add Points</ModalHeader>
          <ModalBody>
            <Row className="mb-2">
              <Col sm={3}>
                <b>Reason</b>
              </Col>
              <Col sm={9}>
                <Input name="reason" value={reason} onChange={this.change.bind(this)} invalid={reason.length < 1}/>
              </Col>
            </Row>
            <Row className="mb-2">
              <Col sm={3}>
                <b>Amount</b>
              </Col>
              <Col sm={9}>
                <Input name="amount"
                       value={amount}
                       type="number"
                       pattern="[0-9]*"
                       onChange={this.change.bind(this)}
                       invalid={amount.length < 1}/>
              </Col>
            </Row>

            <Row className="mb-2">
              <Col sm={3}>
                <b>Type</b>
              </Col>
              <Col sm={9}>
                <Select value={type}
                        name="type"
                        onChange={this.changeType.bind(this)}
                        options={typeOptions}
                        invalid={reason.length < 1}
                />
              </Col>
            </Row>
          </ModalBody>
          <ModalFooter>
            <Button color="primary" disabled={reason.length < 1 || amount.length < 1 || reason.length < 1}
                    onClick={this.addAward.bind(this)}>Add Points</Button>{' '}
            <Button color="secondary" onClick={this.awardModal.bind(this)}>Cancel</Button>
          </ModalFooter>
        </Modal>

        <Modal isOpen={this.state.prizeModal} toggle={this.prizeModal.bind(this)}>
          <ModalHeader toggle={this.prizeModal.bind(this)}>Available Prizes</ModalHeader>
          <ModalBody style={{backgroundColor: "#f5f5f5"}}>
            <ListGroup style={{height: 400, overflowY: 'scroll'}}>
              {prizes?.prizes?.prizes && prizes?.prizes?.prizes.map(p => {
                return <ListGroupItem key={p.id} onClick={this.prizeSelected.bind(this, p.id)}
                                      style={p.id == prizeId && points >= p.points ? {backgroundColor: "#c7e8c7"} : {}}>
                  <Row className="d-flex justify-content-between align-items-center"
                       style={points < p.points ? {opacity: .5} : {}}>
                    <img src={p.icon} className="img-fluid" style={{height: 30, width: 30}}/>
                    <div style={{fontSize: 15, width: "60%"}}>{p.name}</div>
                    <div style={{fontSize: 20}}>{p.points}</div>
                  </Row>
                </ListGroupItem>
              })}
            </ListGroup>
          </ModalBody>
          <ModalFooter>
            <Button color="primary" onClick={this.purchasePrize.bind(this)}>Redeem</Button>{' '}
            <Button color="secondary" onClick={this.prizeModal.bind(this)}>Cancel</Button>
          </ModalFooter>
        </Modal>
      </Card>
    </div>;
  }
}

export default connect(({rewards, awardTypes, purchaseHistory, prizes, points}) => {
  return {rewards, awardTypes, purchaseHistory, prizes, points}
})(Index);
