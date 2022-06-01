import React from 'react';
import moment from 'moment';
import {Row, Col, Modal, ModalHeader, ModalBody, Input, Button} from 'reactstrap';
import Select from '../../../components/select';
import actions from '../actions';
import Uploader from '../../../components/uploader';
import MonthPicker from '../../../components/datePicker/monthPicker';

const paymentTypes = [
  {label: 'AppRent Payment', value: 'AppRent Payment'},
  {label: 'Opening Balance', value: 'Opening Balance'},
  {label: 'Check', value: 'Check'},
  {label: 'Money Order', value: 'Money Order'}
];

const paymentStatus = [
  {label: 'Pending', value: 'pending'},
  {label: 'Cleared', value: 'cleared'},
  {label: 'Failed', value: 'failed'}
];

class EditPayment extends React.Component {
  state = {...this.props.payment, inserted_at: this.props.payment.date};

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  changeAttachment(image) {
    this.setState({image});
  }

  save() {
    const {toggle} = this.props;
    const {inserted_at, post_month} = this.state;
    const params = {
      ...this.state,
      post_month: post_month.format ? post_month.format('YYYY-MM-DD') : post_month,
      inserted_at: inserted_at.format ? inserted_at.format() : inserted_at
    };
    params.image.upload().then(() => {
      params.image.uuid ? params.image = {uuid: params.image.uuid} : delete params.image;
      actions.updatePayment(params).then(toggle);
    });

  }

  render() {
    const {toggle, payment} = this.props;
    const canEdit = payment.status !== 'voided' && !payment.nsf_id && payment.source === 'admin';
    const {description, amount, transaction_id, status, post_month} = this.state;
    const change = this.change.bind(this);
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        Edit Payment
      </ModalHeader>
      <ModalBody>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            Post Month
          </Col>
          <Col sm={9}>
            <MonthPicker onChange={change} month={moment(post_month)} name="post_month"/>
          </Col>
        </Row>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            Description
          </Col>
          <Col sm={9}>
            <Select value={description} name="description" disabled={!canEdit} onChange={change}
                    options={paymentTypes}/>
          </Col>
        </Row>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            ID Number
          </Col>
          <Col sm={9}>
            <Input disabled={!canEdit} value={transaction_id || ''} name="transaction_id" onChange={change}/>
          </Col>
        </Row>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            Amount
          </Col>
          <Col sm={9}>
            <Input disabled={!canEdit} type="number" value={amount || ''} name="amount" onChange={change}/>
          </Col>
        </Row>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            Status
          </Col>
          <Col sm={9}>
            {payment.nsf_id && <Select value='nsf' disabled name="status" options={[{label: 'NSF', value: 'nsf'}]}/>}
            {payment.status === 'voided' &&
            <Select value='voided' disabled name="status" options={[{label: 'Voided', value: 'voided'}]}/>}
            {!payment.nsf_id && payment.status !== 'voided' && <Select value={status} name="status"
                                                                       onChange={change}
                                                                       options={paymentStatus}/>}
          </Col>
        </Row>
        <Row className="mb-3">
          <Col sm={3} className="d-flex align-items-center">
            Image
          </Col>
          <Col sm={9}>
            <Uploader disabled={!!payment.nsf_id} onChange={this.changeAttachment.bind(this)}/>
          </Col>
        </Row>
        <div className="d-flex justify-content-between">
          <div/>
          <Button className="w-50" color="success" onClick={this.save.bind(this)}>
            Save
          </Button>
        </div>
      </ModalBody>
    </Modal>;
  }
}

export default EditPayment;
