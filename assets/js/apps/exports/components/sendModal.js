import React from 'react';
import {Button, Col, Input, Modal, ModalBody, ModalFooter, ModalHeader, Row} from "reactstrap";
import {convertToRaw} from "draft-js";
import {Editor} from 'react-draft-wysiwyg';
import draftToHtml from 'draftjs-to-html';
import Select from "../../../components/select";
import NewRecipient from "./newRecipient";
import actions from "../actions";

class SendModal extends React.Component {
  state = {recipients: [], recipient_ids: []};

  componentDidMount() {
    actions.fetchRecipients().then(r => {
      this.setState({recipients: r.data});
    })
  }

  change({target: {name, value, checked, type}}) {
    this.setState({[name]: type === 'checkbox' ? checked : value});
  }

  changeMessage(message) {
    this.setState({message});
  }

  addRecipient(recipient) {
    const {recipients, recipient_ids} = this.state;
    recipients.push(recipient);
    recipient_ids.push(recipient.id);
    this.setState({recipients: [...recipients], recipient_ids: [...recipient_ids]});
  }

  send() {
    const {document, toggle} = this.props;
    const {recipient_ids, subject, message} = this.state;
    const htmlMessage = draftToHtml(convertToRaw(message.getCurrentContent()));
    actions.sendDocument({id: document.id, recipient_ids, subject, message: htmlMessage}).then(toggle);
  }

  render() {
    const {document, toggle} = this.props;
    const {recipients, recipient_ids, subject, message} = this.state;
    const change = this.change.bind(this);
    return <Modal isOpen={true} size="xl">
      <ModalHeader toggle={toggle}>{document.name}</ModalHeader>
      <ModalBody>
        <Row className="mt-3">
          <Col sm={3}>Recipients</Col>
          <Col className="d-flex">
            <div className="flex-auto">
              <Select multi
                      options={recipients.map(r => {
                        return {label: `${r.name}<${r.email}>`, value: r.id};
                      })}
                      name="recipient_ids"
                      onChange={change} value={recipient_ids}/>
            </div>
            <NewRecipient parent={this}/>
          </Col>
        </Row>
        <Row className="mt-3">
          <Col sm={3}>Subject</Col>
          <Col>
            <Input name="subject" onChange={change} value={subject || ''}/>
          </Col>
        </Row>
        <Row className="mt-3">
          <Col sm={3}>Message</Col>
          <Col>
            <Editor editorState={message}
                    editorStyle={{height: 350}}
                    wrapperId="terms-wrapper"
                    onEditorStateChange={this.changeMessage.bind(this)}
                    toolbar={{
                      options: ['blockType', 'fontSize', 'fontFamily', 'inline', 'list', 'textAlign', 'colorPicker', 'link', 'emoji']
                    }}/>
          </Col>
        </Row>
      </ModalBody>
      <ModalFooter>
        <Button color="danger" onClick={toggle}>Cancel</Button>
        <Button color="success" onClick={this.send.bind(this)}>Save</Button>
      </ModalFooter>
    </Modal>;
  }
}

export default SendModal;