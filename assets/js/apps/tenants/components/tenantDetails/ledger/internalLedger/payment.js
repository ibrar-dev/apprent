import React from 'react';
import {Modal, ModalHeader, ModalBody, Popover, PopoverHeader, PopoverBody} from 'reactstrap';
import moment from 'moment';
import EditPayment from '../editPayment';
import actions from '../../../../actions';
import {toCurr} from '../../../../../../utils';
import confirmation from "../../../../../../components/confirmationModal";

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

  render() {
    const {payment, total, isLocked} = this.props;
    const {showImage, imageUrl, paymentDetails} = this.state;
    const toggle = this.togglePaymentDetails.bind(this);
    const toggleImage = this.showImage.bind(this);
    return <tr className={(payment.status === 'voided' || payment.status === 'nsf') ? 'text-danger' : ''}>
      <td>
        {canEdit("Super Admin") && !isLocked &&
        <a onMouseDown={this.hardDelete.bind(this)} onClick={this.invalidateTimer.bind(this)}>
          <i className="fas fa-trash text-dark"/>
        </a>}
      </td>
      <td>
        {!isLocked && canEdit(["Admin", "Super Admin", "Accountant", "Regional"]) && <a onClick={toggle}>
          <i className="fas fa-pen text-dark"/>
        </a>}
      </td>
      <td>{moment(payment.inserted_at).format('MM/DD/YYYY')}</td>
      <td className="text-center">{moment(payment.post_month).format('MM/YYYY')}</td>
      <td>
        <a href={`/payments/${payment.id}`}>{payment.description} {(payment.description === 'Check' || payment.description === 'Money Order') && `#${payment.transaction_id}`}</a>
        <i className={{ba: 'fas fa-money-check ml-2', cc: 'far fa-credit-card ml-2'}[payment.type]}/>
        {payment.image_id && <a className="ml-2 text-info" onClick={toggleImage}>
          <i className="fas fa-camera"/>
        </a>}
        {payment.post_error && <a className="text-danger" href={`/payments/${payment.id}`} target="_blank">
          <i className="fa fa-exclamation-circle"/> Posting Error
        </a>}
      </td>
      <td/>
      <td>{payment.status === 'voided' && '('}{toCurr(payment.amount)}{payment.status === 'voided' && ')'}</td>
      <td>{toCurr(total)}</td>
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
    </tr>
  }
}

export default Payment;