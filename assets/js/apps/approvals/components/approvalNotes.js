import React, {Component} from "react";
import {
  Row, Col, Modal, ModalHeader, ModalBody,
} from "reactstrap";
import {MentionsInput, Mention} from "react-mentions";
import {connect} from "react-redux";
import actions from "../actions";
import Note from "./Note";
import {defaultMentionStyle, defaultStyle} from "../../../components/mentions/style"

class ApprovalNotes extends Component {
  constructor(props) {
    super(props);
    this.state = {note: ""};
  }

  updateNote(_event, newValue, newPlainText, mentions) {
    this.setState({
      note: newValue,
      mentions,
      plainText: newPlainText,
    });
  }

  saveNote() {
    const {plainText, mentions} = this.state;
    const {approval} = this.props;
    actions.saveApprovalNote({
      note: plainText,
      approval_id: approval.id,
      mentions: [...new Set(mentions.map(m => m.id))],
    });
    this.setState({note: ""});
  }

  scrollToBottom(elem) {
    if (elem) elem.scrollIntoView();
  }

  render() {
    const {
      notes, large, open, toggle, everyone,
    } = this.props;

    const {note} = this.state;
    return (
      <div className="mt-1">
        <div className="labeled-box mt-2 cursor-pointer" onClick={toggle} role="none">
          <i className={`fas fa-comments ${large ? "fa-3x" : ""}`} />
          <span className="badge badge-success">{notes.length}</span>
        </div>
        <Modal isOpen={open} toggle={toggle}>
          <ModalHeader toggle={toggle}>Admin Notes</ModalHeader>
          <ModalBody>
            <div>
              <div style={{maxHeight: "450px", overflowY: "scroll"}}>
                {
                  notes.length > 0 && notes.map((n, i) => (
                    <Note note={n} key={i} last={notes[i] === notes[notes.length - 1]} />
                  ))
                }
                <div ref={this.scrollToBottom} />
              </div>
              <div>
                <Row className="d-flex">
                  <Col md={10} className="pr-0">
                    <MentionsInput
                      placeholder="Add Comment - use @ to notify a person"
                      value={note}
                      allowSpaceInQuery
                      onChange={this.updateNote.bind(this)}
                      style={defaultStyle}
                    >
                      <Mention
                        trigger="@"
                        displayTransform={(_, display) => `@${display}`}
                        data={everyone.map((p) => ({id: p.id, display: `${p.name}`}))}
                        markup="@{{__id__||__display__}}"
                        style={defaultMentionStyle}
                        appendSpaceOnAdd
                      />
                    </MentionsInput>
                  </Col>
                  <Col className="d-flex align-items-center">
                    <i
                      onClick={this.saveNote.bind(this)}
                      className="p-0 fas btn fa-2x fa-paper-plane text-success"
                      role="none"
                    />
                  </Col>
                </Row>
                <Row><Col><small>Use @ to notify that person.</small></Col></Row>
              </div>
            </div>
          </ModalBody>
        </Modal>
      </div>
    );
  }
}

export default connect(({everyone}) => ({everyone}))(ApprovalNotes);
