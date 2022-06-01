import React, {Component} from 'react';
import {Input, ListGroup, ListGroupItem, ListGroupItemHeading, ListGroupItemText} from 'reactstrap';
import moment from 'moment';
import canEdit from '../../../components/canEdit';
import ApprovalLogReasonModal from './approvalLogReasonModal';
import {isUser} from '../../../utils';
import actions from '../actions';


class ApprovalLogs extends Component {
  state = {
    reason: false,
    status: ''
  }

  createApprovalLog(status) {
    const {approval} = this.props;
    if (status === "Declined" || status === "Cancelled") {
      return this.setState({...this.state, status: status, reason: true})
    } else {
      actions.createApprovalLog(approval.id, {status: status})
    }
  }


  deleteApprovalLog(logId){
    const {approval} = this.props;
    actions.deleteApprovalLog(approval.id, logId);
  }

  mostRecentLogForCurrentUser() {
    const {logs} = this.props;
    let f = logs.filter(f => isUser(`${f.admin_id}`))[0];
    return f
  }

  change({target: {value}}) {
    this.setState({...this.state, notes: value})
  }

  toggleReasonModal() {
    this.setState({...this.state, reason: !this.state.reason})
  }

  //Need to do front end sorting as backend sorting causes logs to dupe if more than one attachment...?
  render() {
    const {logs} = this.props;
    const {reason, status} = this.state;
    const sortedLogs = logs.sort((a, b) => moment(b.inserted_at) - moment(a.inserted_at));
    const mostRecent = this.mostRecentLogForCurrentUser();
    return <ListGroup className="w-100 mt-1">
      <ApprovalLogReasonModal open={reason} approval={this.props.approval} status={status} toggle={this.toggleReasonModal.bind(this)} />
      {sortedLogs.length ? sortedLogs.map(l => {
        return <ListGroupItem key={l.id} className="">
          <ListGroupItemHeading>{l.status}<small>{" "}{l.status === "Pending" ? "approval from" : "by"}{" "}</small><span>{l.admin}</span></ListGroupItemHeading>
          <div className="d-flex justify-content-between">
            <div className="d-flex flex-column w-100">
              <div className="d-flex justify-content-between">
                  <span>Date: <b>{moment.utc(l.inserted_at).local().format("MMM D, YY - h:mmA")}</b></span>
                  {(canEdit(["Super Admin", "Regional"]) || isUser(l.admin_id.toString())) && <i onClick={this.deleteApprovalLog.bind(this, l.id)} className="fas fa-trash text-danger" />}
              </div>
              {isUser(`${l.admin_id}`) && l.id === mostRecent.id && <span className="d-flex justify-content-end">
                  {l.status !== "Approved" && <i onClick={this.createApprovalLog.bind(this, "Approved")} className="far fa-thumbs-up text-green"/>}
                  {l.status !== "Declined" && <i onClick={this.createApprovalLog.bind(this, "Declined")} className="far ml-1 fa-thumbs-down text-red"/>}
                </span>}
              {l.notes && <span>Reason: {l.notes}</span>}
            </div>
          </div>
        </ListGroupItem>
      }) : ""}
    </ListGroup>
  }
}

export default ApprovalLogs