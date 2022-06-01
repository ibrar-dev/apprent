import React from 'react';
import {Button} from 'reactstrap';
import canEdit from '../../../../components/canEdit';
import confirmation from "../../../../components/confirmationModal";
import Notes from './notes';
import PeriodModal from "./periodModal";
import Packages from "./packages";
import LeaseSelect from "./leaseSelect";
import actions from "../../actions";

class Period extends React.Component {
  state = {};

  toggleOpen() {
    this.setState({open: !this.state.open});
  }

  toggleEdit() {
    this.setState({editMode: !this.state.editMode});
  }

  requestApproval() {
    confirmation("Please confirm that you are requesting approval from regionals for these package options.").then(() => {
      const {period} = this.props;
      actions.updatePeriod(period.id, {approval_request: true})
    })
  }

  approve() {
    confirmation("Please confirm your approval of these renewal offers. Approving will lock these rates for any leases wanting to renew during the dates.").then(() => {
      const {period} = this.props;
      actions.updatePeriod(period.id, {approve: true})
    })
  }

  deletePeriod() {
    confirmation("Really delete this lease period?").then(() => {
      actions.deletePeriod(this.props.period.id);
    })
  }

  changeLease({target: {value}}) {
    this.setState({lease: this.props.period.leases.find(l => l.id === value)});
  }

  editLeasePackage(packages) {
    this.setState({lease: {...this.state.lease, custom_packages: packages}});
  }

  printLetters() {
    confirmation("Print all renewal letters?").then(() => {
      this.setState({printing: true});
      const _this = this;
      const printFrame = document.createElement('iframe');
      printFrame.style.width = '0';
      printFrame.style.height = '0';
      printFrame.style.border = 'none';
      printFrame.src = `/api/lease_periods/${this.props.period.id}?print=true`;
      printFrame.onload = () => {
        printFrame.focus();
        printFrame.contentWindow.print();
        _this.setState({printing: false});
      };
      document.body.appendChild(printFrame);
    })
  }

  render() {
    const {period} = this.props;
    const {open, printing, editMode, lease} = this.state;
    period.packages.sort((a, b) => a.min - b.min);
    const locked = !!period.approval_admin;
    return <>
      <tr>
        <td className="align-middle">
          <a onClick={this.toggleOpen.bind(this)}>
            <i className={`fas fa-2x fa-caret-${open ? 'down' : 'right'}`}/>
          </a>
        </td>
        <td className="align-middle nowrap">
          {period.start_date} - {period.end_date} ({period.leases.length} Leases)
        </td>
        <td>
          <LeaseSelect period={period} lease={lease} onChange={this.changeLease.bind(this)}/>
        </td>
        <td className="align-middle text-right nowrap">
          {locked && `Approved by ${period.approval_admin} on ${period.approval_date}`}
          {locked &&
          <Button className="ml-2" outline color="success" disabled={printing} onClick={this.printLetters.bind(this)}>
            {printing ? <i className="fas fa-spin fa-sync-alt"/> : <i className="fas fa-print"/>}
          </Button>}
          {canEdit(["Super Admin", "Regional"]) && !period.approval_admin &&
          <Button color="success" onClick={this.approve.bind(this)}>
            Approve
          </Button>}
          {!locked && <>
            {!canEdit(["Super Admin", "Regional"]) &&
            <Button className="ml-3" color="success" onClick={this.requestApproval.bind(this)}>
              Request Approval
            </Button>}
            <Button className="ml-3" color="info" onClick={this.toggleEdit.bind(this)}>
              Edit
            </Button>
            <Button className="ml-3" color="danger" onClick={this.deletePeriod.bind(this)}>
              Delete
            </Button>
          </>}
        </td>
        <td className="align-middle">
          <Notes notes={period.notes} period={period} data={period} module="period" large={true}/>
        </td>
      </tr>
      {open && <Packages locked={locked} period={period} lease={lease} edit={this.editLeasePackage.bind(this)}/>}
      {editMode && <PeriodModal period={period} toggle={this.toggleEdit.bind(this)}/>}
    </>;
  }
}

export default Period;