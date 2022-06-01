import React from 'react';
import classNames from 'classnames';
import moment from 'moment';
import {toCurr} from '../../../../../../utils';
import actions from '../../../../actions';
import canEdit from '../../../../../../components/canEdit';
import EditCharge from '../editCharge';
import confirmation from '../../../../../../components/confirmationModal';
import {Modal, ModalBody, ModalFooter, ModalHeader} from "reactstrap";

const description = (charge) => {
  if (charge.status === 'reversal') {
    return `Reversal of ${charge.account}: ${moment(charge.reversed_date).format('MM/DD/YYYY')}`;
  }
  return charge.account;
};

class Charge extends React.Component {
  state = {};

  edit() {
    this.setState({edit: !this.state.edit});
  }

  hardDelete() {
    this.timer = setTimeout(() => {
      confirmation('Completely delete this charge?').then(() => {
        actions.hardDeleteCharge(this.props.charge);
      })
    }, 2000);
  }

  invalidateTimer() {
    clearTimeout(this.timer);
  }

  showImage() {
    const {charge} = this.props;
    actions.getPaymentImageURL(charge.id, "nsf_proof").then(r => {
      this.setState({showImage: !this.state.showImage, imageUrl: r.data});
    });
  }

  render() {
    const {charge, total, isLocked} = this.props;
    const {edit, showImage, imageUrl} = this.state;
    const toggleImage = this.showImage.bind(this);
    return <>
      <tr className={classNames({
        'text-danger': charge.reversal_id || charge.account === "NSF Fees" || charge.nsf_description,
        'font-weight-bold': charge.status === 'charge'
      })}>
        <td/>
        <td>
          {!charge.reversal_id && !isLocked && canEdit(["Admin", "Super Admin", "Accountant", "Regional"]) && <a onMouseDown={this.hardDelete.bind(this)}
                                                  onMouseUp={this.invalidateTimer.bind(this)}
                                                  onClick={this.edit.bind(this)}>
            <i className="fas fa-pen"/>
          </a>}
        </td>
        <td>{moment(charge.bill_date).format('MM/DD/YYYY')}</td>
        <td className="text-center">{moment(charge.post_month).format('MM/YYYY')}</td>
        <td className="nowrap">
          {description(charge)}
          {charge.image_id && <a className="ml-2 text-info" onClick={this.showImage.bind(this)}>
            <i className="fas fa-camera"/>
          </a>}
        </td>
        {charge.nsf_id ? <td/> : <td>{toCurr(charge.amount)}</td>}
        {charge.nsf_id ? <td>{toCurr(charge.amount * -1)}</td> : <td/>}
        <td>{toCurr(total)}</td>
        <td>
          {charge.description}
        </td>
        <td>
          {charge.admin}
        </td>
      </tr>
      {edit && <EditCharge charge={charge} toggle={this.edit.bind(this)}/>}
      {showImage && <Modal isOpen={true} toggle={toggleImage} size="lg">
        <ModalHeader toggle={toggleImage}>
          {charge.nsf_description} {charge.nsf_transaction_id}
        </ModalHeader>
        <ModalBody>
          {imageUrl.content_type === 'application/pdf' &&
          <iframe style={{height: 750}} className="w-100" src={imageUrl.url}/>}
          {imageUrl.content_type !== 'application/pdf' &&
          <img className="img-fluid" src={imageUrl.url} alt="Payment Image"/>}
        </ModalBody>
        <ModalFooter className="d-flex justify-content-start">
          {charge.admin} - Reason: {charge.description || "N/A"}
        </ModalFooter>
      </Modal>}
    </>;
  }
}

export default Charge;