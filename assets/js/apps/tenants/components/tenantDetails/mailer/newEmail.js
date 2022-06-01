import React, {Component} from 'react';
import {validate, ValidatedInput} from "../../../../../components/validationFields";
import {Row, Col, Button} from 'reactstrap';
import {EditorState, convertToRaw} from 'draft-js';
import {Editor} from 'react-draft-wysiwyg';
import draftToHtml from 'draftjs-to-html';
import actions from '../../../actions';

class NewEmail extends Component {
  state = {subject: "", body: EditorState.createEmpty(), attachments: []};

  updateSubject(e) {
    this.setState({...this.state, subject: e.target.value})
  }

  updateBody(editorState) {
    this.setState({...this.state, body: editorState})
  }

  sendEmail() {
    const {subject, body, attachments} = this.state;
    const email = {
      body: draftToHtml(convertToRaw(body.getCurrentContent())),
      tenant_id: this.props.tenant.id,
      subject,
      attachments
    };
    actions.sendEmail(email).then(this.clearContents());
  }

  ableToSend() {
    const {subject, body} = this.state;
    return (subject.length <= 3 || draftToHtml(convertToRaw(body.getCurrentContent())).length <= 11);
  }

  clearContents() {
    this.setState({...this.state, body: EditorState.createEmpty(), subject: ""});
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

  render() {
    const {subject, body, attachments} = this.state;
    return <div>
      <Row>
        <Col sm={1} className="mb-3 d-flex align-items-center">
          <div>Subject:</div>
        </Col>
        <Col className="mb-3 ml-3">
          <ValidatedInput context={this} validation={(v) => v.length > 1}
                          feedback="Subject is required" type="text"
                          name="subject" value={subject}
                          onChange={this.updateSubject.bind(this)}/>
        </Col>
      </Row>
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
            <a className="btn btn-light rounded-circle border"
               style={{width: 32, height: 32, paddingLeft: 8, paddingTop: 4}}>
              <i className="icon-paper-clip"/>
            </a>
          </label>
        </Col>
      </Row>
      <Row className="mb-3">
        <Col sm={1}/>
        <Col>
          <div className="ml-3">
            <Editor editorState={body}
                    toolbar={{
                      options: ['blockType', 'fontSize', 'fontFamily', 'inline', 'list', 'textAlign', 'colorPicker', 'link', 'embedded', 'emoji', 'image', 'remove', 'history'],
                    }}
                    onEditorStateChange={this.updateBody.bind(this)}/>
          </div>
        </Col>
      </Row>
      <Row>
        <Col sm={1}/>
        <Col>
          <div className="ml-3">
            <Button onClick={this.sendEmail.bind(this)} disabled={this.ableToSend()} outline color="success">
              Send Now
            </Button>
          </div>
        </Col>
      </Row>
    </div>
  }
}

export default NewEmail;