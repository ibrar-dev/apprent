import React, {Component} from 'react';
import {connect} from 'react-redux';
import {EditorState, convertToRaw} from 'draft-js';
import {Editor} from 'react-draft-wysiwyg';
import draftToHtml from 'draftjs-to-html';
import 'react-dates/initialize';
import DatePicker from "../../../components/datePicker";
import isInclusivelyBeforeDay from "react-dates/lib/utils/isInclusivelyBeforeDay";
import times from '../../../components/timeSelector';
import Select from '../../../components/select';
import moment from 'moment';
import actions from '../actions';
import {Card, CardHeader, CardBody, Collapse, Input} from 'reactstrap';
import {Modal, ModalHeader, ModalBody, ModalFooter, Row, Col, Button} from 'reactstrap';
import confirmation from '../../../components/confirmationModal';
import shortCodes from './shortCodeMentions';
import Templates from './templates';
import canEdit from '../../../components/canEdit';

class Body extends Component {
  state = {
    expand: true,
    subject: "",
    body: EditorState.createEmpty(),
    attachments: [],
    recurring: false,
    send_at: {
      date: null,
      time: null,
      modal: false
    },
  };

  toggleRecurring() {
    this.setState({...this.state, recurring: !this.state.recurring})
  }

  toggleExpand() {
    this.setState({...this.state, expand: !this.state.expand})
  }

  updateSubject(e) {
    this.setState({...this.state, subject: e.target.value})
  }

  updateBody(editorState) {
    this.setState({...this.state, body: editorState})
  }

  setTemplate(subject, editorState) {
    this.setState({...this.state, subject: subject, body: EditorState.createWithContent(editorState)})
  }

  addAttachment({target: {files}}) {
    const {attachments} = this.state;
    [...Array(files.length)].forEach((s, index) => {
      attachments.push(files[index]);
    });
    this.setState({attachments});
  }

  deleteAttachment(index) {
    const {attachments} = this.state;
    attachments.splice(index, 1);
    this.setState({attachments});
  }

  ableToSend() {
    const {selectedRecipients} = this.props;
    const {subject, body} = this.state;
    const selected = selectedRecipients.filter(r => r.checked);
    return (subject.length <= 3 || draftToHtml(convertToRaw(body.getCurrentContent())).length <= 11 || (selected && selected.length < 1));
  }

  ableToSave() {
    const {subject, body} = this.state;
    return (subject.length <= 3 || draftToHtml(convertToRaw(body.getCurrentContent())).length <= 11 || !canEdit(["Super Admin", "Regional"]) || this.templateExists())
  }

  templateExists() {
    const {templates} = this.props;
    const {subject} = this.state;
    let subjects = templates.map(t => t.subject);
    return subjects.includes(subject);
  }

  clearAll() {
    this.setState({
      subject: "",
      body: EditorState.createEmpty(),
      attachments: [],
      send_at: {date: null, time: null}
    }, () => actions.clearSelection());
    this.setState({
      subject: "",
      body: EditorState.createEmpty(),
      attachments: [],
      send_at: {date: null, time: null},
      modal: false
    })
  }

  sendEmail() {
    const {selectedRecipients} = this.props;
    const {subject, body, attachments, send_at} = this.state;
    const bodyHTML = draftToHtml(convertToRaw(body.getCurrentContent()));
    confirmation(`Please confirm that you would like to send this email to ${selectedRecipients.filter(r => r.checked).length} people.`).then(() => {
      actions.createMailing(selectedRecipients.filter(r => r.checked), {subject, attachments, body: bodyHTML}, send_at);
    });
  }

  updateSendAt(type, e) {
    const {send_at} = this.state;
    if (type === 'asap') return this.setState({...this.state, send_at: {date: null, time: null}});
    send_at[type] = e;
    if (type === 'time') send_at.time = e.target.value;
    if (type === 'time' && !send_at.date) send_at.date = moment();
    this.setState({...this.state, send_at})
  }

  filteredOptions() {
    const {send_at: {date}} = this.state;
    const current_time = moment().diff(moment().startOf('day'), 'minutes');
    if (moment(date).format('YYYY-MM-DD') === moment().format('YYYY-MM-DD')) {
      return times.filter(t => t.value > current_time);
    } else {
      return times
    }
  }

  saveTemplate() {
    const {subject, body} = this.state;
    confirmation('Please confirm that you would like to save this template.').then(() => {
      const bodyHTML = draftToHtml(convertToRaw(body.getCurrentContent()));
      actions.createTemplate({subject, body: bodyHTML})
    })
  }

  toggleMailingModal() {
    this.setState(prevState => ({
        modal: !prevState.modal
      })
    )
  }

  clearRecipients() {
    actions.clearSelection();
    this.setState({modal: false})
  }

  clearSubjectLine() {
    this.setState({subject: "", modal: false})
  }

  clearMessage() {
    this.setState({body: EditorState.moveFocusToEnd(EditorState.createEmpty()), modal: false})
  }

  render() {
    const {templates} = this.props;
    const {subject, expand, body, attachments, recurring, send_at} = this.state;
    return <Card>
      <CardHeader style={{cursor: 'pointer'}} onClick={this.toggleExpand.bind(this)}
                  className="d-flex justify-content-between"><span>Subject Content Schedule</span><i
        className={`fas fa-caret-${expand ? 'up' : 'down'}`}/></CardHeader>
      <Collapse isOpen={expand}>
        <CardBody>
          <Row>
            <Col>
              <Card>
                <CardHeader onClick={this.toggleRecurring.bind(this)}>Schedule</CardHeader>
                <Collapse isOpen={recurring}>
                  <CardBody>
                    <Row>
                      <Col>
                        <Button onClick={this.updateSendAt.bind(this, 'asap')} outline color="info"
                                active={!send_at.date && !send_at.time}>ASAP</Button>
                      </Col>
                      <Col>
                        <div className="form-group">
                          <label className="d-block">
                            Scheduled Date
                          </label>
                          <DatePicker value={send_at.date}
                                      disabled={attachments.length >= 1}
                                      isOutsideRange={day => isInclusivelyBeforeDay(day, moment().subtract(1, 'days'))}
                                      onChange={this.updateSendAt.bind(this, 'date')}/>
                        </div>
                      </Col>
                      <Col>
                        <div className="form-group">
                          <label className="d-block">
                            Scheduled Date
                          </label>
                          <Select value={send_at.time}
                                  disabled={!send_at.date}
                                  options={this.filteredOptions().map(t => {
                                    return {value: t.value, label: t.label}
                                  })}
                                  onChange={this.updateSendAt.bind(this, 'time')}
                                  placeholder="Delivery Time"/>
                        </div>
                      </Col>
                    </Row>
                  </CardBody>
                </Collapse>
              </Card>
            </Col>
          </Row>
          {templates.length >= 1 && <Templates setBody={this.setTemplate.bind(this)} state={this.state}/>}
          <Row>
            <Col sm={12}>
              <div className="form-group">
                <Input value={subject} name="subject" onChange={this.updateSubject.bind(this)}/>
              </div>
              <Row>
                <Col sm={1} className="mb-3 d-flex align-items-center">
                  <div>Attachments:</div>
                </Col>
                <Col className="mb-3 ml-3 d-flex justify-content-between">
                  <div className="d-flex">
                    {attachments.map((a, i) => {
                      return <small key={a.name + i}
                                    className="d-flex align-items-center p-2 mr-2 border border-info text-info"
                                    style={{borderRadius: 4}}>
                        <a onClick={this.deleteAttachment.bind(this, i)}>
                          <i className="fas fa-times"/>
                        </a>
                        <div className="ml-1">{a.name}({Math.round(a.size / 1000)}K)</div>
                      </small>
                    })}
                  </div>
                  <label className="d-flex justify-content-end align-items-center" style={{width: 35}}>
                    <input type="file" className="invisible" multiple onChange={this.addAttachment.bind(this)}/>
                    <a className="btn btn-light rounded-circle border disabled"
                       style={{width: 32, height: 32, paddingLeft: 8, paddingTop: 4}}>
                      <i className="icon-paper-clip"/>
                    </a>
                  </label>
                </Col>
              </Row>
              <div className="form-group">
                <Editor editorState={body}
                        toolbar={{
                          options: ['blockType', 'fontSize', 'fontFamily', 'inline', 'list', 'textAlign', 'colorPicker', 'link', 'embedded', 'emoji', 'image', 'remove', 'history']
                        }}
                        mention={{suggestions: shortCodes, separator: ' ', trigger: '@'}}
                        onEditorStateChange={this.updateBody.bind(this)}/>
              </div>
            </Col>
          </Row>
          <Row>
            <Col className="d-flex">
              <Button className="p-2" outline color="info" disabled={this.ableToSave()}
                      onClick={this.saveTemplate.bind(this)}>Save Template</Button>
              <Button className="p-2" outline color="warning"
                      onClick={this.toggleMailingModal.bind(this)}>Clear</Button>
              <Modal isOpen={this.state.modal} toggle={this.toggleMailingModal.bind(this)}
                     className={this.props.className}>
                <ModalHeader toggle={this.toggleMailingModal.bind(this)}> Mailings</ModalHeader>
                <ModalBody className="d-flex justify-content-between">
                  <Button color="secondary" onClick={this.clearRecipients.bind(this)}>Clear Recipients</Button>{' '}
                  <Button color="secondary" onClick={this.clearSubjectLine.bind(this)}>Clear Subject Line</Button>{' '}
                  <Button color="secondary" onClick={this.clearMessage.bind(this)}>Clear Message</Button>{' '}
                  <Button color="primary" onClick={this.clearAll.bind(this)}>Clear all</Button>{' '}
                </ModalBody>
                <ModalFooter>
                  <Button color="danger" onClick={this.toggleMailingModal.bind(this)}>Back</Button>{''}
                </ModalFooter>
              </Modal>
              <Button className="ml-auto p-2" onClick={this.sendEmail.bind(this)} disabled={this.ableToSend()} outline
                      color="success">
                {!send_at.date ? 'Send' : 'Schedule'}
              </Button>
            </Col>
          </Row>
        </CardBody>
      </Collapse>
    </Card>
  }
}

export default connect(({selectedRecipients, templates}) => {
  return {selectedRecipients, templates}
})(Body)