import React from 'react';
import moment from "moment";
import {Popover, PopoverBody, PopoverHeader} from "reactstrap";
import ScreeningModal from "./screeningModal";
import ApprovalModal from "./approvalModal";
import AttachBlueMoon from "./attachBluemoonModal";

const statusList = ['submitted', 'screened', 'preapproved', 'lease_sent', 'signed'];

const canEdit = (role) => {
  return (window.roles.includes("Super Admin") || window.roles.includes(role));
};

const multiCanEdit = (roles = []) => {
  return roles.some((r) => window.roles.includes(r));
};

class ApplicationStatus extends React.Component {
  state = {};

  showDeclinedReason() {
    this.setState({showDeclinedReason: !this.state.showDeclinedReason});
  }

  toggleModal(modal) {
    if (modal === 'lease') {
      const {history, application: {id}} = this.props;
      return history.push(`/applications/${id}/lease`, {});
    }
    this.setState({modal})
  }

  stageIndicator(currentLevel, level, modal, buttonText, plainText) {
    if (buttonText && currentLevel === level - 1) {
      if(level === 3 && !multiCanEdit(["Super Admin", "Admin", "Regional"]) ){
        return <div className="font-weight-bold text-info text-center flex-auto">
          <u>{buttonText}</u>
        </div>
      }
      return <a className="font-weight-bold text-info text-center flex-auto"
                onClick={this.toggleModal.bind(this, modal)}>
        <u>{buttonText}</u>
      </a>;
    }
    const icon = currentLevel >= level ? 'fa-check-circle text-success' : 'fa-times text-danger';
    if(level === 2 && currentLevel >= level && canEdit("Super Admin")) {
      return <div className="flex-auto text-center">
        <a onClick={this.toggleModal.bind(this, "bypass")}><i className={`fas ${icon}`}/> {plainText || modal}</a>
        </div>;
    }
      return <div className="flex-auto text-center"><i className={`fas ${icon}`}/> {plainText || modal}</div>;
  };

  render() {
    const {application} = this.props;
    const level = statusList.indexOf(application.status);
    const percentage = application.declined_on ? 100 : ((level + 1) * 100.0 / statusList.length);
    const color = application.declined_on ? '#f9e1e6' : '#b5d3c0';
    const {showDeclinedReason, modal} = this.state;
    const gradient = `linear-gradient(90deg, ${color} ${percentage - 5}%, transparent ${percentage + 5}%)`;
    return <tr>
      <td className="border-0" style={{background: color}}/>
      <td colSpan={5} className="border-0 p-0">
        <div className="d-flex justify-content-between p-2"
             style={{background: application.declined_on || application.status === 'signed' ? color : gradient}}>
          <div className="flex-auto text-center">
            <i
              className="fas fa-check-circle text-success"/> Submitted: {moment.utc(application.inserted_at).local().format("YYYY-MM-DD")}
          </div>
          {!application.declined_on && <>
            {this.stageIndicator(level, 1, 'screen', 'View Screening', `Screened${application.is_conditional ? ': Conditional' : ''}`)}
            {this.stageIndicator(level, 2, 'approve', 'Lease Info', 'Awaiting Lease Creation')}
            {this.stageIndicator(level, 3, 'lease', 'Create Lease', 'Signature Request Sent')}
            {this.stageIndicator(level, 4, 'Signed')}
          </>}
          {application.declined_on && <div className="d-flex">
            <div className="mr-2 nowrap">
              Declined by <b>{application.declined_by}</b> on <b>{application.declined_on}</b>
            </div>
            <a onClick={this.showDeclinedReason.bind(this)} id={`declined-reason-${application.id}`}>
              <i className="fas fa-question-circle"/>
            </a>
            <Popover placement="top" isOpen={showDeclinedReason} target={`declined-reason-${application.id}`}
                     toggle={this.showDeclinedReason.bind(this)}>
              <PopoverHeader>Reason</PopoverHeader>
              <PopoverBody>{application.declined_reason}</PopoverBody>
            </Popover>
          </div>}
        </div>
        {modal === 'screen' && <ScreeningModal persons={application.persons.filter(p => p.status === 'Lease Holder')}
                                               toggle={this.toggleModal.bind(this)}
                                               applicationId={application.id}/>}
        {modal === 'approve' && <ApprovalModal unit={application.unit}
                                               params={application.approval_params}
                                               persons={application.persons}
                                               toggle={this.toggleModal.bind(this)}
                                               applicationId={application.id}
                                               propertyId={application.property.id}/>}
        {modal === "bypass" && <AttachBlueMoon application={application}  toggle={this.toggleModal.bind(this)}/>}
      </td>
    </tr>;
  }
}

export default ApplicationStatus;
