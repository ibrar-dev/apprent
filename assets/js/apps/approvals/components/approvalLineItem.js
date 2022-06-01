import React, {Component} from 'react';
import {connect} from "react-redux";
import {toCurr} from '../../../utils';
import moment from "moment";

class ApprovalLineItem extends Component {
  state = {}

  getApprovers() {
    const {approval: {logs}} = this.props;
    if (!logs.length) return []
    return logs.filter((l, pos, arr) =>{
      return arr.map(mapObj => mapObj["admin_id"]).indexOf(l["admin_id"]) === pos;
    })
  }

  getApproverStatus(admin_id) {
    const {approval: {logs}} = this.props;
    const sortedLogs = logs.sort((a, b) => moment(b.inserted_at) - moment(a.inserted_at));
    const mostRecent = sortedLogs.filter(l => l.admin_id === admin_id)[0];
    const {status} = mostRecent;
    if (status === "Approved") {
      return "success";
    } else if (status === "Declined") {
      return "danger";
    } else if (status === "More Info Requested") {
      return "warning"
    } else {
      return "info"
    }
  }

  fullyApproved() {
    const {approval: {logs}} = this.props;
    if (!logs || !logs.length) return false;
    let approvers = this.getApprovers();
    return approvers.every(a => this.getApproverStatus(a.admin_id) === "success")
  }

  checkIfCancelled() {
    const {approval: {logs}} = this.props;
    if (!logs || !logs.length) return "";
    if (logs.filter(l => l.status === "Cancelled").length >= 1) return "alert-warning";
    if (logs.filter(l => l.status === "Declined" || l.status === "Denied").length >= 1) return "alert-danger";
    return ""
    // let cancelled = logs.filter(l => l.status === "Declined" || l.status === "Denied" || l.status === "Cancelled");
    // return cancelled.length >= 1
  }

  getVendor() {
    const {approval: {params}, payees} = this.props;
    let payee = payees.filter(p => p.id === params.payee_id)[0]
    if (payee && payee.name) return payee.name;
    return "N/A"
  }

  getAmount() {
    const {approval: {params}} = this.props;
    if (params.amount) return toCurr(params.amount);
    return "N/A"
  }

  viewApproval() {
    const {approval} = this.props;
    window.location.pathname = `/approvals/${approval.id}`
  }

  extractUnit() {
    const {approval} = this.props;
    let match = approval.params.description.match(/Unit-(?!.*Unit-)(.*)/);
    if (match && match.length) return match[1];
    return "No Unit"
  }

  render() {
    const {approval} = this.props;
    const approvers = this.getApprovers();
    return <tr className={`cursor-pointer ${this.fullyApproved() ? 'alert-success' : ''} ${this.checkIfCancelled()}`} onClick={this.viewApproval.bind(this)}>
      <td>{approval.type === "purchase" ? this.getVendor() : 'N/A'}</td>
      <td>{approval.requestor.name}</td>
      <td>{moment.utc(approval.inserted_at).local().format("MMM D")}</td>
      <td>{this.extractUnit()}</td>
      <td>{this.fullyApproved() ? approval.num : 'N/A'}</td>
      <td>
        {
          approval.costs.map((cost) => (
            <div key={cost.id} style={{textTransform: "capitalize"}}>
              {cost.amount.toLocaleString('en-US', { style: 'currency', currency: 'USD' })}
              {" - "}
              {cost.category_name.toLowerCase().replace(/\b\w/g, l => l.toUpperCase())}
            </div>
          ))
        }
      </td>
      <td>{this.getAmount()}</td>
      <td>
        {approvers.map(a => {
          return <div key={a.id} className={`border-0 `}>
            <div><span className={`alert-${this.getApproverStatus(a.admin_id)}`}>{a.admin}</span></div>
          </div>
        })}
        {!approvers.length && <td className="border-0">
          <div><span className="alert-warning">Nobody Notified</span></div>
        </td>}
      </td>
    </tr>
  }
}

export default connect(({payees}) => {
  return {payees}
})(ApprovalLineItem)