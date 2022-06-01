import {Component} from "react";
import React from "react";
import {Card, CardBody, CardHeader, Col, Modal, Row} from "reactstrap";
import moment from 'moment';

class PaymentReport extends Component {

    createResponse(response){
        if(response && response.account_number){
            return response.account_number.split("XXXX").join("");
        }else{
            return null;
        }
    }

    render(){
        const {payment_report: {id, transaction_id, amount, description, applicant, date, post_month, response}} = this.props;
        return <tr key={id}>
            <td>{date === "Total" ? <strong>Total</strong> : moment(date).format('MM-DD-YYYY')}</td>
            <td>${amount}</td>
            <td>{applicant && applicant.map(a => <Row key={a.id}>{a.name}</Row>)}</td>
            <td>{transaction_id}</td>
            <td>{description}</td>
            <td>{this.createResponse(response)}</td>
        </tr>
    }
}

export default PaymentReport;
