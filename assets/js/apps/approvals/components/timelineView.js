import React, {Component} from "react";
import { VerticalTimeline, VerticalTimelineElement }  from "react-vertical-timeline-component";
import {Row, Col, Collapse} from "reactstrap";
import {MentionsInput, Mention} from "react-mentions"
import moment from "moment";
import {connect} from "react-redux";
import icons from "../../../components/flatIcons";
import {toCurr} from "../../../utils";
import actions from "../actions";
import {defaultMentionStyle, defaultStyle} from "../../../components/mentions/style"

const approvalInfo = ({data}, payees, fullyApproved) => {
  return <div className="card border-success">
    <div className="card-header bg-transparent">
      Request Created by: {data.requestor.name}
    </div>
    <div className="card-body text-secondary">
      <h5 className="card-title">
        Number Assigned: {fullyApproved ? data.num : "Not Yet Approved"}
      </h5>
      <p className="card-text">
        The amount is for {toCurr(data.params.amount) || "N/A"} to
        {payees.filter(p => p.id === data.params.payee_id)[0].name || "N/A"}
        with a description of {data.params.description || "N/A"}
      </p>
    </div>
  </div>
}

const logInfo = ({data}) => {
  return <div className="card border-info">
    <div className="card-header bg-transparent">{data.status}</div>
    <div className="card-body text-secondary">
      <h5 className="card-title">
        {`${data.status} ${data.status === "Pending" ? "approval from" : "by"} ${data.admin}`}
      </h5>
      <p className="card-text">
        {data.status === "Pending" && `${data.admin} was notified about the request and is able to approve or deny.`}
        {data.status != "Pending" && `${data.admin} viewed the request and chose to ${data.status} it.`}
      </p>
    </div>
  </div>
}

class NoteInfo extends Component {
  state = {
    note: "",
    expand: false
  }

  toggleExpand() {
    this.setState({...this.state, expand: !this.state.expand})
  }

  updateNote({target: {value}}, newValue, newPLainText, mentions) {
    this.setState(
      {
        ...this.state,
        note: newValue,
        mentions: mentions,
        plainText: newPLainText
      }
    )
  }

  saveNote() {
    const {plainText, mentions} = this.state;
    const {data} = this.props;
    actions.saveApprovalNote(
      {
        note: plainText,
        approval_id: data.approval_id,
        mentions: mentions.map(m => m.id)
      }
    )

    this.setState({...this.state, note: "", expand: false})
  }

  render() {
    const {data, everyone} = this.props;
    const {note, expand} = this.state;
    return <div className="card border-primary">
      <div className="card-header bg-transparent">
        {data.admin} added a note.
      </div>
      <div className="card-body text-secondary">
        <p className="card-text">
          {data.note}
        </p>
      </div>
      <div className="card-body">
        <a
          onClick={this.toggleExpand.bind(this)}
          className="btn btn-outline-primary card-link">{expand ? "Hide" : "Add My 2 Cents"}
        </a>
        <Collapse isOpen={expand}>
          <div className="d-flex flex-column">
            <Row>
              <Col md={10} className="pr-0">
                <MentionsInput
                  placeholder="Add Comment..."
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
                  className="p-0 fas btn fa-2x fa-plus-square text-success"
                />
              </Col>
            </Row>
            <small>
              Use @ to mention anyone you would like to be notified of the new note.
            </small>
            <small>
              Replying directly to others notes is not available yet, your
              comment will be added to the notes on this approval request.
            </small>
          </div>
        </Collapse>
      </div>
    </div>
  }
}

const attachmentInfo = ({data}) => {
  return (
    <div className="card border-dark">
      {data.content_type.includes("image") && <img className="card-img-top" src={data.url} />}
      {data.content_type.includes("pdf") && <iframe src={data.url} frameBorder="0" />}
      <div className="card-body">
        <h5 className="card-title">{data.filename}</h5>
        <a href={data.url} download className="card-link">Download</a>
        <a href={data.url} target="_blank" className="card-link">View</a>
      </div>
    </div>
  )
}

class TimelineView extends Component {
  constructor(props) {
    super(props);
    const events = this.sortApproval(props.approval);
    this.state = {events: events}
  }

  sortApproval(approval) {
    let events = [];
    events.push({type: "approval", date: approval.inserted_at, data: approval});
    if (approval.logs) {
      approval.logs.forEach(l => events.push({type: "log", date: l.inserted_at, data: l}))
    }
    if (approval.attachments) {
      approval.attachments.forEach(l => events.push({type: "attachment", date: l.inserted_at, data: l}))
    }
    if (approval.admin_notes) {
      approval.admin_notes.forEach(l => events.push({type: "note", date: l.inserted_at, data: l}))
    };
    return events.sort((a, b) => moment(a.date) - moment(b.date));
  }

  getIcon(type) {
    switch (type) {
      case "approval":
        return (
          <img
            src={icons.request}
            style={{borderRadius: "20px", backgroundColor: "#5DBD77"}}
            height="65"
          />
        )
      case "log":
        return (
          <img
            src={icons.log}
            style={{borderRadius: "20px", backgroundColor: "#8349CC"}}
            height="65"
          />
        )
      case "attachment":
        return (
          <img
            src={icons.attachment}
            style={{borderRadius: "20px", backgroundColor: "#849989"}}
            height="65"
          />
        )
      case "note":
        return (
          <img
            src={icons.note}
            style={{borderRadius: "20px", backgroundColor: "#A8FF75"}}
            height="65"
          />
        )
    }
  }

  render() {
    const {payees, everyone, fullyApproved} = this.props;
    const {events} = this.state;
    return (
      <VerticalTimeline>
        {events.map((e, i) => {
          return (
            <VerticalTimelineElement
              key={i}
              iconStyle={{opacity: ".8"}}
              icon={this.getIcon(e.type)}
              style={{boxShadow: "none"}}
              contentStyle={{boxShadow: "none"}}
              date={moment.utc(e.date).local().format("MM/DD/YY h:mmA")}
            >
              {e.type === "approval" && approvalInfo(e, payees, fullyApproved)}
              {e.type === "log" && logInfo(e)}
              {e.type === "attachment" && attachmentInfo(e)}
              {e.type === "note" && <NoteInfo data={e.data} everyone={everyone}/>}
            </VerticalTimelineElement>
          )
        })}
      </VerticalTimeline>
    )
  }
}

export default connect(({payees, everyone}) => {
  return {payees, everyone}
})(TimelineView)
