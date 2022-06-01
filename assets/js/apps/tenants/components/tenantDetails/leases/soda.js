import React, {Component} from 'react';
import {Modal, ModalHeader, ModalBody, Card, CardHeader,Nav, NavItem, TabContent, NavLink, CardBody, Collapse, Input, Row, Col, TabPane, CardFooter, Button} from 'reactstrap';
import actions from '../../../actions';
import {connect} from 'react-redux';
import classnames from 'classnames';

const chargeTypes = ["Kitchen", "Doors", "Walls", "Flooring", "Closet", "Blinds", "Window", "Bathroom", "Electric", "Smoke Alarm", "Keys", "Cleaning", "Lawn Damage", "Other"];

class Soda extends Component{
    state={};

    addCharge(tab){
        const charges = this.state[tab] || [];
        charges.push({status: "MoveOutReason", type: '', cost: 0 });
        this.setState({...this.state, [tab]: charges});
    }

    change(state, idx, type) {
        const newCharges = this.state[type];
        const oldCharge = this.state[type][idx];
        newCharges[idx] = Object.assign(oldCharge, state);
        this.setState({...this.state, [type]: newCharges});
    }

    toggleActiveTab(tab){
        if(this.state.activeTab !== tab){
            this.setState({...this.state, activeTab: tab})
        }
    }

    submit(){
        const {toggle, lease, toggleSodaReport} = this.props;
        let allCharges = [];
        chargeTypes.forEach( cT => {
            if(this.state[cT]) {
                const currCharges = this.state[cT].map(c => {
                  return {...c, category: cT};
                });
                allCharges = allCharges.concat(currCharges);
            }
        });
        const result = {soda: {lease_id: lease.id, charges: allCharges}};
        actions.createCharges(result).then(toggle).then(toggleSodaReport);
    }

    render(){
        const {toggle} = this.props;
        const {status} = this.state;
        return <Modal size="lg" isOpen={true} toggle={toggle}>
            <ModalHeader>Soda</ModalHeader>
            <ModalBody>
                <Nav tabs>
                {chargeTypes.map((t,i) => <NavItem>
                    <NavLink className={classnames({ active: this.state.activeTab === i })}
                             onClick={this.toggleActiveTab.bind(this, i)}>{t}</NavLink>
                </NavItem>)}
                </Nav>
                <TabContent activeTab={this.state.activeTab}>
                {chargeTypes.map((t, i) => <TabPane tabId={i}>
                        <Card>
                  <CardHeader>{t}</CardHeader>
                      <CardBody>
                          {this.state[t] && this.state[t].map((c,i) => <Charge idx={i} type={t} status={status} change={this.change.bind(this)}/>)}
                          <Button outline color="info" className="mt-3" onClick={this.addCharge.bind(this, t)}>+ Add Charge</Button>
                      </CardBody>
                    </Card>
                </TabPane>)}
                </TabContent>
                <div className="d-flex justify-content-center">
                    <Button onClick={this.submit.bind(this)} className="mt-3">Submit</Button>
                </div>
            </ModalBody>
        </Modal>
    }
}

class Charge extends Component{
    state = {};

    change(field, e){
        const {idx, type} = this.props;
        this.setState({...this.state, [field]: e.target.value}, () => this.props.change(this.state, idx, type, field));
    }

    render(){
        const {status, type, cost} = this.state;
        return <div className="mt-3">
            <Row>
                <Col>
                    <Input type="select" name="status" onChange={this.change.bind(this, "status")} value={status}>
                        <option value="Damage">Damage</option>
                        <option value="Replace">Replace</option>
                        <option value="Other">Other</option>
                    </Input>
                </Col>
            </Row>
            <Row className="mt-3">
                <Col>
                    <Input placeholder={"Type"} value={type} onChange={this.change.bind(this, "type")} />
                </Col>
                <Col>
                    <Input placeholder={"Cost"} value={cost} onChange={this.change.bind(this, "cost")} />
                </Col>
            </Row>
        </div>
    }
}

export default connect(({account, tenant}) => {
    return {account, tenant};
})(Soda)