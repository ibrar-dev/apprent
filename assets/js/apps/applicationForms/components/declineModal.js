import React from 'react';
import {Input, Modal, ModalBody, ModalFooter, ModalHeader, Button} from "reactstrap";
import actions from "../actions";

class DeclineModal extends React.Component {
  state = {declined_reason: ''};

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  declineApplication() {
    const {applicationId, toggle} = this.props;
    const {declined_reason} = this.state;
    actions.declineApplication(applicationId, declined_reason).then(toggle);
  }

  render() {
    const {toggle} = this.props;
    const {declined_reason} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>Reason for Declining</ModalHeader>
      <ModalBody>
        <Input value={declined_reason} onChange={this.change.bind(this)} name="declined_reason"/>
      </ModalBody>
      <ModalFooter>
        {declined_reason.length >= 5 &&
        <Button outline color="success" disabled={declined_reason.length <= 5}
                onClick={this.declineApplication.bind(this)}>Save</Button>}
      </ModalFooter>
    </Modal>;
  }
}

export default DeclineModal;