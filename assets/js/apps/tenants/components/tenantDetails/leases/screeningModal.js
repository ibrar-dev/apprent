import React from 'react';
import {Modal, ModalHeader, ModalBody, Table, ModalFooter, Button} from 'reactstrap';
import confirmation from "../../../../../components/confirmationModal";
import actions from '../../../actions';

const classKey = {
  Fail: 'danger',
  Approved: 'success'
};

class ScreeningModal extends React.Component {
  state = {};

  reject() {
    confirmation('Permanently reject this tenant?').then(() => {
      const {screening, toggle} = this.props;
      actions.deleteScreening(screening.id).then(toggle);
    });
  }

  approve() {
    confirmation('Approve this tenant and add them to the lease?').then(() => {
      const {screening, toggle} = this.props;
      actions.approveScreening(screening.id).then(toggle);
    });
  }

  render() {
    const {toggle, screening} = this.props;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        Screening Status for {screening.first_name} {screening.last_name}
      </ModalHeader>
      <ModalBody>
        <Table>
          <tbody>
          <tr>
            <td>
              <span className={`badge badge-${classKey[screening.decision] || 'info'}`}>
                {screening.decision}
              </span>
            </td>
            <td>
              <a href={screening.url} target="_blank">View Report</a>
            </td>
          </tr>
          </tbody>
        </Table>
      </ModalBody>
      <ModalFooter>
        <Button color="danger" onClick={this.reject.bind(this)}>Reject</Button>
        <Button color="success" onClick={this.approve.bind(this)}>Approve and add to lease</Button>
      </ModalFooter>
    </Modal>;
  }
}

export default ScreeningModal;