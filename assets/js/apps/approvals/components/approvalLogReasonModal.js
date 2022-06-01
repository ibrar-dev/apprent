import React, {Component} from 'react';
import {Modal, ModalHeader, ModalBody, Row, Col, Input} from 'reactstrap';
import actions from '../actions';
import {validate, ValidatedInput} from "../../../components/validationFields";

class ApprovalLogReasonModal extends Component {
  state = {
    notes: ''
  }

  changeNote({target: {value}}) {
    this.setState({...this.state, notes: value})
  }

  createApprovalLog() {
    const {approval, status} = this.props;
    const {notes} = this.state;
    validate(this).then(() => {
      actions.createApprovalLog(approval.id, {status: status, notes: notes}).then(() => {
        this.setState({...this.state, notes: ''});
        this.props.toggle();
      })
    })
  }

  render() {
    const {open, toggle, status} = this.props;
    const {notes} = this.state;
    return <Modal isOpen={open} toggle={toggle}>
      <ModalHeader toggle={toggle}>Please enter a reason for {status}</ModalHeader>
      <ModalBody>
        <Row>
          <Col>
            <div className="labeled-box">
              <ValidatedInput context={this}
                              validation={(d) => !!d}
                              name="notes"
                              value={notes}
                              onChange={this.changeNote.bind(this)}
                              feedback="A reason is required" />
              <div className="labeled-box-label">Reason</div>
            </div>
          </Col>
        </Row>
        <Row className="mt-1">
          <Col>
            <button className="btn btn-outline-success btn-block" onClick={this.createApprovalLog.bind(this)}>Save</button>
          </Col>
        </Row>
      </ModalBody>
    </Modal>
  }
}

export default ApprovalLogReasonModal;