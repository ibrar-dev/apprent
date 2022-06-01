import React, {Component} from 'react';
import {Row, Col, Modal, ModalHeader, ModalBody, Input, Button, ModalFooter} from 'reactstrap';
import DatePicker from '../../../../../components/datePicker';
import confirmation from '../../../../../components/confirmationModal';
import moment from 'moment';
import actions from '../../../actions';
import Uploader from '../../../../../components/uploader';
import snackbar from '../../../../../components/snackbar';

class NSFPayment extends Component {
  state = {
    proof: null,
    reason: '',
    date: moment()
  };

  change({target: {name, value}}) {
    this.setState({...this.state, [name]: value});
  }

  changeDate({target: {name, value}}) {
    const paymentDate = moment(this.props.payment.inserted_at);
    if(value > paymentDate) {
      this.setState({...this.state, [name]: value})
    }else{
      snackbar({
        message: `Can't post a nsf before their payment date of ${paymentDate.format("MMM Do YYYY")}.`,
        args: {type: 'error'}
      });
    }
  }

  changeAttachment(proof) {
    this.setState({...this.state, proof});
  }

  save() {
    confirmation('Please confirm that this payment was returned and you would like to mark it NSF').then(() => {
      const {payment, toggle, tenant} = this.props;
      const {proof, reason, date} = this.state;
      const params = {nsf_id: payment.id, tenant_id: tenant.id, lease_id: payment.lease_id, description: reason};
      params.bill_date = moment(date).format("YYYY-MM-DD");
      proof.upload().then(() => {
        if (proof.uuid) params.image = {uuid: proof.uuid};
        actions.markNSF({nsf: params}).then(() => toggle('close'));
      });
    });
  }

  render() {
    const {toggle} = this.props;
    const {reason, date} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>Mark Payment as Insufficient Funds</ModalHeader>
      <ModalBody>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            Date
          </Col>
          <Col sm={9}>
            <DatePicker required value={date} name="date" onChange={this.changeDate.bind(this)}/>
          </Col>
        </Row>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            Proof
          </Col>
          <Col sm={9}>
            <Uploader onChange={this.changeAttachment.bind(this)}/>
          </Col>
        </Row>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            Reason
          </Col>
          <Col sm={9}>
            <Input type="text" value={reason} name="reason" onChange={this.change.bind(this)}/>
          </Col>
        </Row>
      </ModalBody>
      <ModalFooter className="d-flex justify-content-between">
        <Button outline color="success" onClick={toggle}>Cancel</Button>
        <Button outline color="warning" onClick={this.save.bind(this)}>Mark NSF</Button>
      </ModalFooter>
    </Modal>
  }
}

export default NSFPayment;