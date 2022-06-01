import React, {Component} from 'react';
import {Modal, ModalHeader, ModalBody, Card, CardHeader,Nav, NavItem, TabContent, NavLink, CardBody, Collapse, Input, Row, Col, TabPane, CardFooter, Button} from 'reactstrap';
import actions from '../../../actions';
import {connect} from 'react-redux';

class SodaReport extends Component{
    state={};

    calculateBalance(charges){
        let balance = 0;
        charges.forEach(c => balance += c.amount)
        return balance;
    }

    render(){
        const {tenant, toggle} = this.props;
        const moveOutCharges = tenant.charges.filter(c => c.account === "Move Out Charge");
        const otherCharges = this.calculateBalance(tenant.charges.filter(c => c.account != "Move Out Charge"));
        const payments = this.calculateBalance(tenant.payments);
        let balance = (otherCharges - payments).toFixed(2);

        return <Modal size="lg" isOpen={true} toggle={toggle}>
            <ModalHeader>Soda Report</ModalHeader>
            <ModalBody>
                <Row>
                    <Col>Date</Col>
                    <Col>Description</Col>
                    <Col>Charges</Col>
                    {/*<Col>Payment</Col>*/}
                    <Col>Balance</Col>
                </Row>
                <Row>
                    <Col></Col>
                    <Col>Balance Forward</Col>
                    <Col></Col>
                    <Col>{balance}</Col>
                </Row>
                {moveOutCharges.map(mC => {
                    balance = parseInt(balance) + parseInt(mC.amount);
                    return <Row>
                        <Col>{mC.bill_date}</Col>
                        <Col>{mC.description}</Col>
                        <Col>{mC.amount}</Col>
                        <Col>{balance}</Col>
                    </Row>
                })}
            </ModalBody>
        </Modal>
    }
}

export default connect(({tenant}) => {
    return {tenant};
})(SodaReport)