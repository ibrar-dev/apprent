import React, {Component} from 'react';
import {connect} from 'react-redux';
import {withRouter} from "react-router-dom";
import {Button, Popover, PopoverHeader, PopoverBody, Col, Row} from 'reactstrap';
import actions from '../../actions';
import TabbedBox from '../../../../components/tabbedBox';
import {BasicInfo, Basics, SecurityDeposit, BedBugs, Concessions, Gate, Other, WasherDryer, Finish} from "./steps";
import defaultLease from "./defaultLease";
import confirmation from '../../../../components/confirmationModal';

const links = [
  {icon: false, data: Basics, label: 'Basics', id: 0},
  {icon: false, data: SecurityDeposit, label: 'Security Deposit & Keys', id: 1},
  {icon: false, data: BedBugs, label: 'Bed Bugs', id: 2},
  {icon: false, data: Concessions, label: 'Concessions', id: 3},
  {icon: false, data: Gate, label: 'Gate Access', id: 4},
  {icon: false, data: WasherDryer, label: 'Washer/Dryer', id: 5},
  {icon: false, data: Other, label: 'Other', id: 6},
  {icon: false, data: Finish, label: 'Execute', id: 7},
];

class LeaseCreation extends Component {
  constructor(props) {
    super(props);
    this.state = {tab: links[0], lease: {}};
    actions.fetchLease(props.match.params.id);
  }

  componentWillReceiveProps(nextProps, nextContext) {
    this.setState({lease: defaultLease(nextProps.lease)});
  }

  updateApplication() {
    actions.updateLease(this.state.lease);
  }

  setTab(tab) {
    this.setState({tab});
  }

  toggleInfo() {
    this.setState({infoOpen: !this.state.infoOpen})
  }

  _footer() {
    const {infoOpen} = this.state;
    return <div>
      <Button onClick={this.toggleInfo.bind(this)} id="lease-info" color="info" className="btn-block mt-3">
        Lease Info
      </Button>
      <Popover placement="right" isOpen={infoOpen} target="lease-info" toggle={this.toggleInfo.bind(this)}>
        <PopoverHeader>Lease Info</PopoverHeader>
        <PopoverBody>
          <BasicInfo/>
        </PopoverBody>
      </Popover>
      <Button onClick={() => this.props.history.push("/applications", {})} color="danger" className="btn-block mt-3">
        Back
      </Button>
    </div>;
  }

  change(field, value) {
    this.setState({lease: {...this.state.lease, [field]: value}});
  }

  unlockLease() {
    confirmation('Unlock this lease?').then(() => {
      actions.unlockLease(this.state.lease);
    }).catch(() => {
    });
  }

  render() {
    const {tab, lease} = this.state;
    if (!lease.approval_params) return <div/>;
    return <TabbedBox links={links}
                      active={tab.id}
                      header={<div className={`d-flex card-header align-items-center ${lease.locked && 'text-danger'}`}
                                   style={{border: '1px solid #e4e6eb', borderBottom: 'none'}}>
                        {lease.approval_params.first_name} {lease.approval_params.last_name}{lease.locked && '(Locked)'}
                        {lease.locked && window.roles.includes("Super Admin") &&
                        <a className="ml-auto" onClick={this.unlockLease.bind(this)}>
                          <i className="fas fa-lock-open"/>
                        </a>}
                      </div>}
                      footer={this._footer()}
                      onNavigate={this.setTab.bind(this)}>
      <div className="pl-4">
        <tab.data lease={lease} onChange={this.change.bind(this)}/>
        <Row>
          <Col className='d-flex justify-content-between'>
            <div/>
            <Button disabled={lease.locked} onClick={this.updateApplication.bind(this)} color="success" outline>
              Save
            </Button>
          </Col>
        </Row>
      </div>
    </TabbedBox>
  }
}

export default withRouter(connect(({lease}) => {
  return {lease};
})(LeaseCreation));