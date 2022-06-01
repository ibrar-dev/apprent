import React, {Component} from 'react';
import {connect} from "react-redux";
import {Row, Col, CardHeader, CardBody, Input, Popover, Tooltip} from 'reactstrap';
import moment from 'moment';
import {titleize, isUser} from "../../../utils";
import confirmation from '../../../components/confirmationModal';
import canEdit from '../../../components/canEdit';
import snackbar from '../../../components/snackbar';
import Select from '../../../components/select';
import Uploader from '../../../components/uploader';
import icons from '../../../components/flatIcons';
import {TypePurchase} from './approvalTypes';
import actions from '../actions';
import Attachments from './attachments';
import ApprovalLogs from './approvalLogs';
import ApprovalLogReasonModal from './approvalLogReasonModal';
import ApprovalNotes from './approvalNotes';
import Timeline from './timelineView';

class Approval extends Component {
  state = {
    approval: {},
    popover: false,
    approver: [],
    openNotes: false,
    timeline: false,
    reason: false,
    status: ''
  };

  constructor(props) {
    super(props);
    actions.fetchApproval(props.match.params.id);
  }

  getProperty() {
    const {approval, properties} = this.props;
    let p = properties.filter(p => p.id === approval.property_id)[0];
    if (p) return p.name;
    return "N/A"
  }

  getClass() {
    const {approval} = this.props;
    if (!approval || !approval.logs || !approval.logs.length) return "";
    if (approval.logs[0].status === "Approved") return "success";
    if (approval.logs[0].status === "Declined") return "warning";
    if (approval.logs[0].status === "Request More Info") return "info";
    return "";
  }

  getStatus() {
    const {approval} = this.props;
    if (!approval || !approval.logs || !approval.logs.length) return "Not Yet Requested";
    return `${approval.logs[0].status} - ${approval.logs[0].admin}`;
  }

  createApprovalLog(status) {
    const {approval} = this.props;
    if (status === "Declined" || status === "Cancelled") {
      return this.setState({...this.state, status: status, reason: true})
    } else {
      actions.createApprovalLog(approval.id, {status: status})
    }
  }

  toggleReasonModal() {
    this.setState({...this.state, reason: !this.state.reason})
  }

  editPage(){
    this.setState({editPage: true});
  }

  savePage(){
    const approval = {...this.props.approval};
    if (!approval.params.amount) return snackbar({
      message: "Please select at least one category and amount.",
      args: {type: 'error'}
    });
    if(this.refs){
      confirmation("All non-pending approval logs will be deleted for this approval request will be deleted if this request is edited.").then( () => {
        const approvalParams = this.refs.typePurchase.state.approval.params;
        approval.params = approvalParams;
        approval.attachments = null;
        actions.updateApproval(approval.id, approval).then(() => this.setState({editPage: false}))
      })
    }
  }

  togglePopover() {
    this.setState({...this.state, popover: !this.state.popover})
  }

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  saveApprover(type) {
    const {approver} = this.state;
    const {approval} = this.props;
    approver.map(a => actions.createApprovalLog(approval.id, {admin_id: a, status: 'Pending', type: type}))
  }

  addAttachment(newAttachments) {
    newAttachments[0] && newAttachments.forEach(attachment => {
      if (attachment.filename) {
        attachment.upload().then(() => {
          actions.updateApproval(this.props.approval.id, {attachments: [{uuid: attachment.uuid}]}).then(() => actions.fetchApproval(this.props.approval.id))
        });
        this.refs.view_uploader && this.refs.view_uploader.clear();
      }
    })
  }

  componentWillUnmount() {
    actions.storeAttachment([])
  }

  fullyApproved() {
    const {approval: {logs}} = this.props;
    if (!logs || !logs.length) return false;
    let approvers = this.getApprovers();
    return approvers.every(a => this.getApproverStatus(a.admin_id) === "success")
  }

  getApprovers() {
    const {approval: {logs}} = this.props;
    if (!logs.length) return [];
    return logs.filter((l, pos, arr) =>{
      return arr.map(mapObj => mapObj["admin_id"]).indexOf(l["admin_id"]) === pos;
    })
  }

  getApproverStatus(admin_id) {
    const {approval: {logs}} = this.props;
    const mostRecent = logs.filter(l => l.admin_id === admin_id)[0];
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

  toggleNotes() {
    this.setState({...this.state, openNotes: !this.state.openNotes})
  }

  toggleTimeline() {
    this.setState({...this.state, timeline: !this.state.timeline})
  }

  toggleInvoicePopover() {
    this.setState({...this.state, invoicePopover: !this.state.invoicePopover})
  }

  confirmInvoice() {
    const {approval} = this.props;
    confirmation("Please confirm that you have received the invoice for this approval request. Doing so will remove it from the Approved list and help us keep track what's been invoiced and what has not yet").then(() => {
      approval.params.invoice_date = moment().format("MM/DD/YYYY");
      approval.params.invoice_admin = window.current_user;
      approval.attachments = null;
      actions.updateApproval(approval.id, approval);
    })
  }

  render() {
    const {payees, approvers, attachments, approval, accountingCategories} = this.props;
    const {popover, approver, editPage, openNotes, timeline, reason, status, invoicePopover} = this.state;
    return <Row>
      <ApprovalLogReasonModal approval={approval} status={status} open={reason} toggle={this.toggleReasonModal.bind(this)} />
      <Col>
        <CardHeader className={`alert-${this.getClass()} d-flex justify-content-between`}>
          <div>
            <a href="/approvals"><i style={{color: "red"}} className="fas fa-arrow-left" /></a>
            <span className="ml-2">{approval.type === "purchase" ? 'PO' : 'Request'} {this.fullyApproved() ? approval.num : 'Not Yet Approved'}</span>
          </div>
          <img height="30" width="30" className="cursor-pointer img-fluid" onClick={this.toggleTimeline.bind(this)} style={{opacity: ".8"}} src={icons.timeline}/>
          <div>
            {!this.fullyApproved() && <React.Fragment>
              {!editPage && <a onClick={this.editPage.bind(this)}><i className="far fa-edit" />Edit</a>}
              {editPage && <a onClick={this.savePage.bind(this)}><i className="far fa-save" />Save Request</a>}
            </React.Fragment>}
            {(approval.requestor && isUser(`${approval.requestor.id}`)) && <i onClick={this.createApprovalLog.bind(this, "Cancelled")} className="ml-1 cursor-pointer alert-danger fas fa-trash" />}
          </div>
        </CardHeader>
        <CardBody>
          {timeline && <Timeline approval={approval} fullyApproved={this.fullyApproved()} toggle={this.toggleTimeline.bind(this)} timeline={timeline} />}
          {!timeline && <Row>
            <Col className="d-flex flex-column">
              <div className="labeled-box">
                <Input value={this.getProperty()} disabled/>
                <div className="labeled-box-label">Property</div>
              </div>
              <div className="labeled-box mt-3">
                <Input value={titleize(approval.type || "")} disabled />
                <div className="labeled-box-label">Approval Type</div>
              </div>
              {approval.type === "purchase" && <TypePurchase ref="typePurchase" editPage={editPage} approval={approval} payees={payees} accountingCategories={accountingCategories} />}
              {canEdit(["Super Admin", "Regional"]) && <div className="d-flex justify-content-between mt-4">
                  <i onClick={this.createApprovalLog.bind(this, "Approved")} className="far fa-thumbs-up text-green fa-5x cursor-pointer" />
                  <i onClick={this.createApprovalLog.bind(this, "Declined")} className="far ml-1 fa-thumbs-down text-red fa-5x cursor-pointer" />
                  {/*<i onClick={this.createApprovalLog.bind(this, "More Info Requested")} className="far ml-1 fa-question-circle fa-5x text-warning cursor-pointer" />*/}
              </div>}
            </Col>
            <Col className="d-flex flex-column">
              <div className="labeled-box">
                <Input value={approval.requestor ? approval.requestor.name : ""} disabled/>
                <div className="labeled-box-label">Submitted By</div>
              </div>
              <div className="labeled-box mt-3">
                <Input value={moment.utc(approval.inserted_at).local().format("MM/DD/YY")} disabled/>
                <div className="labeled-box-label">Date of Expense</div>
              </div>
              <div className={`labeled-box mt-3`}>
                <Input value={this.getStatus()} disabled/>
                <div className="labeled-box-label">Status</div>
              </div>
              <div className="labeled-box mt-3">
                <Input value={attachments ? attachments.length : ""} disabled/>
                <div className="labeled-box-label">Attachments</div>
              </div>
              {editPage && <Uploader multiple ref="view_uploader" onChange={this.addAttachment.bind(this)} placeholder="Click or Drag Here"/>}
              <Attachments editPage={editPage} attachments={attachments || []} approval={approval} />
              <div className="d-flex justify-content-between">
                <ApprovalNotes approval={approval} open={openNotes} toggle={this.toggleNotes.bind(this)} notes={approval.admin_notes || []} large={true} />
                {approval.type === "purchase" && this.fullyApproved() && <React.Fragment>
                  <i id="invoiced-popover" onClick={(!approval.params["invoice_admin"] && canEdit(["Super Admin", "Accountant"])) ? this.confirmInvoice.bind(this) : null} className="fas fa-dollar-sign fa-3x" />
                  {approval.params["invoice_admin"] && <Tooltip target="invoiced-popover" isOpen={invoicePopover} toggle={this.toggleInvoicePopover.bind(this)}>
                    <span>Invoiced by {approval.params["invoice_admin"]} on {approval.params["invoice_date"]}</span>
                  </Tooltip>}
                </React.Fragment>}
              </div>
              <div className="d-flex mt-3 justify-content-between">
                <div className="labeled-box w-75">
                  <Input value={approval.logs ? approval.logs.length : ""} disabled/>
                  <div className="labeled-box-label">Approval Logs</div>
                </div>
                <i id="bug-popover" className="fas fa-plus-square fa-2x" />
              </div>
              <div style={{height: 450, overflow: "scroll"}}>
                <ApprovalLogs approval={approval} logs={approval.logs || []} />
              </div>
            </Col>
            <Popover placement="left" isOpen={popover} target="bug-popover" toggle={this.togglePopover.bind(this)}>
              <div className="d-flex flex-column flex-content-center">
                <Select name="approver"
                        className="m-2"
                        value={approver}
                        multi={true}
                        onChange={this.change.bind(this)}
                        options={approvers.map(p => {
                          return {label: p.name, value: p.id}
                        })} />
                <div className="d-flex justify-content-center">
                  <span style={{color: approver.length > 0 ? 'green' : 'red'}} className="m-2 cursor-pointer"><i onClick={this.saveApprover.bind(this, "bug")} className="fas fa-bug fa-2x" /></span>
                  <span style={{color: approver.length > 0 ? 'green' : 'red'}} className="m-2 cursor-pointer"><i onClick={this.saveApprover.bind(this, "add")} className="fas fa-cart-plus fa-2x" /></span>
                </div>
                <p className="m-2">Select people to alert about this approval.</p>
                <p className="m-2">Click the beetle to remind them, click the cart to add them as necessary approvers to this order.</p>
              </div>
            </Popover>
          </Row>}
        </CardBody>
      </Col>
    </Row>
  }
}

export default connect(({properties, payees, approval, approvers, attachments, accountingCategories}) => {
  return {properties, payees, approval, approvers, attachments, accountingCategories}
})(Approval)
