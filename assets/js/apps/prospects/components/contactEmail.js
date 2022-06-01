import React, {Component} from 'react';
import {Modal, ModalHeader, ModalBody,
  Button, ButtonGroup, ModalFooter,
  Row, Col, Input
} from 'reactstrap';
import actions from "../actions";

class ContactEmail extends Component {
  state = {
    contactType: "send",
    notes: ''
  }

  setContactType(type) {
    this.setState({...this.state, contactType: type});
  }

  changeNotes(e) {
    this.setState({...this.state, notes: e.target.value});
  }

  clear() {
    this.setState({...this.state, successfulSave: false, notes: '', contactType: "send"});
  }

  saveNote() {
    const {contactType, notes} = this.state;
    const memo = {notes: notes, send: contactType === "send", prospect_id: this.props.prospect.id};
    actions.saveMemo(memo).then(this.setState({...this.state, successfulSave: true, notes: ''}));
  }

  render() {
    const {prospect, toggle} = this.props;
    const {contactType, notes, successfulSave} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>Contact {prospect.name}</ModalHeader>
      <ModalBody>
        <div className="d-flex">
          <ButtonGroup className="flex-fill">
            <Button className="flex-fill" active={contactType === "send"} onClick={this.setContactType.bind(this, "send")} outline size="sm">Send Email</Button>
            <Button className="flex-fill" active={contactType === "log"} onClick={this.setContactType.bind(this, "log")} outline size="sm">Log Interaction</Button>
          </ButtonGroup>
        </div>
        <Row className='mt-1'>
          {successfulSave && <Col><h4>Successfully Saved</h4></Col>}
          {contactType === "send" && !successfulSave && <Col>
            <h5>Dear {prospect.name}</h5>
            <p>Thank you for your interest in {prospect.property.name}.</p>
            <Input type='textarea' value={notes} onChange={this.changeNotes.bind(this)} />
            <h6 className='mt-1'>Thank You</h6>
            <span className='text-monospace'>Your name will go here in the email sent to the prospect</span>
          </Col>}
          {contactType === "log" && !successfulSave && <Col>
            <h6>Log any interactions or memos you have had with a prospect here.</h6>
            <Input type='textarea' value={notes} onChange={this.changeNotes.bind(this)} />
            <small>This will NOT send an email to the prospect. To do so please click the "Send Email" button above.</small>
          </Col>}
        </Row>
      </ModalBody>
      <ModalFooter>
        {!successfulSave && <Button outline color='success' onClick={this.saveNote.bind(this)}>{contactType === "send" ? "Send" : "Save"}</Button>}
        {successfulSave && <Button outline color='warning' onClick={this.clear.bind(this)}>Start Over</Button>}
      </ModalFooter>
    </Modal>
  }
}

export default ContactEmail;