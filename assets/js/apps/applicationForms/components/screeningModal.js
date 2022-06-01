import React from 'react';
import {Modal, ModalHeader, ModalBody, ModalFooter, Input, Button, Table} from 'reactstrap';
import {InputGroup, InputGroupAddon} from 'reactstrap';
import confirmation from '../../../components/confirmationModal';
import actions from '../actions';

const classKey = {
  Fail: 'danger',
  Approved: 'success'
};

class ScreeningModal extends React.Component {
  state = {rent: ''};

  change({target: {name, value}}) {
    this.setState({[name]: value})
  }

  doScreen() {
    const {toggle, applicationId, persons} = this.props;
    if (persons[0].screening_status) {
      actions.getScreeningStatus(applicationId);
    } else {
      actions.submitScreening(applicationId, parseFloat(this.state.rent)).then(toggle);
    }
  }

  approve(is_conditional) {
    const {toggle, applicationId} = this.props;
    confirmation(`Approve this screening result${is_conditional ? ' and mark as conditional' : ''}?`).then(() => {
      actions.updateApplicationStatus({is_conditional, status: 'screened', id: applicationId}).then(toggle);
    });
  }

  render() {
    const {toggle, applicationId, persons} = this.props;
    const {rent} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>Screening Status for Application #{applicationId}</ModalHeader>
      <ModalBody>
        {persons[0].screening_status && <Table className="m-0">
          <tbody>
          {persons.map(p => <tr key={p.id}>
            <td className="border-0">
              {p.full_name}
            </td>
            <td className="border-0">
              <span className={`badge badge-${classKey[p.screening_decision] || 'info'}`}>
                {p.screening_decision}
              </span>
            </td>
            <td className="border-0">
              <a href={p.screening_url} target="_blank">View Report</a>
            </td>
            <td className="border-0">
              <a href={`/screenings/${p.screening_id}`} target="_blank">Print AA Letter</a>
            </td>
          </tr>)}
          </tbody>
        </Table>}
        {!persons[0].screening_status && <div>
          <InputGroup className="labeled-box">
            <Input value={rent} onChange={this.change.bind(this)} name="rent" className="h-auto"/>
            <InputGroupAddon addonType="append">
              <Button color="success" disabled={(parseInt(rent) < 400) || rent.length <= 0}
                      onClick={this.doScreen.bind(this)}>
                Screen Now
              </Button>
            </InputGroupAddon>
            <div className="labeled-box-label"><b>Total</b> Rent Amount</div>
          </InputGroup>
        </div>}
      </ModalBody>
      <ModalFooter>
        <Button color="danger" onClick={this.approve.bind(this, true)}>
          Mark Conditional
        </Button>
        <Button color="success" onClick={this.approve.bind(this, false)}>
          Approve Screening
        </Button>
      </ModalFooter>
    </Modal>;
  }
}

export default ScreeningModal;