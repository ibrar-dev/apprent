import React from 'react';
import {Modal, ModalHeader, ModalBody} from 'reactstrap';
import moment from 'moment';
import EditPayment from './editPayment';
import RefundPayment from './refundPayment';
import actions from '../actions';
import {toCurr} from '../../../utils';
import confirmation from "../../../components/confirmationModal";

const canEdit = (role) => {
  return (window.roles.includes("Super Admin") || window.roles.includes(role));
};

class Payment extends React.Component {
  state = {};

  remove() {
    confirmation('Remove this payment?').then(() => {
      actions.deletePayment(this.props.payment);
    });
    this.invalidateTimer();
  }

  hardDelete() {
    this.timer = setTimeout(() => {
      confirmation('Completely delete this payment?').then(() => {
        actions.hardDeletePayment(this.props.payment);
      })
    }, 2000);
  }

  invalidateTimer() {
    clearTimeout(this.timer);
  }

  showImage() {
    const {payment} = this.props;
    actions.getPaymentImageURL(payment.id).then(r => {
      this.setState({...this.state, showImage: !this.state.showImage, imageUrl: r.data});
    });
  }

  togglePaymentDetails() {
    this.setState({paymentDetails: !this.state.paymentDetails});
  }

  toggleRefund() {
    this.setState({refund: !this.state.refund});
  }

  render() {
    const {payment} = this.props;
    const {showImage, imageUrl, paymentDetails, refund} = this.state;
    const toggle = this.togglePaymentDetails.bind(this);
    const toggleImage = this.showImage.bind(this);
    return <tr className={(payment.status === 'voided' || payment.status === 'nsf') ? 'text-danger' : ''}>
      <td>
        {canEdit(["Admin", "Super Admin", "Accountant", "Regional"]) && !payment.refund_date &&
        <a onClick={this.toggleRefund.bind(this)}>
          <i className="fas fa-reply text-dark"/>
        </a>}
      </td>
      <td>
        {canEdit(["Admin", "Super Admin", "Accountant", "Regional"]) && <a onClick={toggle}>
          <i className="fas fa-pen text-dark"/>
        </a>}
      </td>
      <td>{moment(payment.date).format('MM/DD/YYYY')}</td>
      <td className="text-center">{moment(payment.post_month).format('MM/YYYY')}</td>
      <td>
        <a
          href={`/payments/${payment.id}`}>{payment.description} {(payment.description === 'Check' || payment.description === 'Money Order') && `#${payment.transaction_id}`}</a>
        {payment.image_id && <a className="ml-2 text-info" onClick={toggleImage}>
          <i className="fas fa-camera"/>
        </a>}
        {payment.refund_date && <span> [REFUNDED]</span>}
      </td>
      <td>{payment.status === 'voided' && '('}{toCurr(payment.amount)}{payment.status === 'voided' && ')'}</td>
      <td>
        {payment.status === 'nsf' ? 'NSF' : payment.status}
        {payment.memo && payment.memo}
      </td>
      <td>
        {payment.admin}
      </td>
      {showImage && <Modal isOpen={true} toggle={toggleImage} size="lg">
        <ModalHeader toggle={toggleImage}>
          {payment.description} {(payment.description === 'Check' || payment.description === 'Money Order') && `#${payment.transaction_id}`}
        </ModalHeader>
        <ModalBody>
          {imageUrl.content_type === 'application/pdf' &&
          <iframe style={{height: 750}} className="w-100" src={imageUrl.url}/>}
          {imageUrl.content_type !== 'application/pdf' &&
          <img className="img-fluid" src={imageUrl.url} alt="Payment Image"/>}
        </ModalBody>
      </Modal>}
      {paymentDetails && <EditPayment payment={payment} toggle={toggle}/>}
      {refund && <RefundPayment payment={payment} toggle={this.toggleRefund.bind(this)}/>}
    </tr>
  }
}

export default Payment;