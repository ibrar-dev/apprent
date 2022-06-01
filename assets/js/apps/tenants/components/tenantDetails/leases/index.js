import React from 'react';
import {
  Card,
  CardHeader,
  CardBody,
  Nav,
  NavItem,
  NavLink,
  ButtonGroup,
  Button,
  Badge,
  Col,
  UncontrolledPopover,
  PopoverBody
} from 'reactstrap';
import Lease from './lease';
import NewLease from './newLease';
import MoveOut from './moveOutModal';
import Eviction from './eviction';
import CaptureLease from './captureLease';
import canEdit from '../../../../../components/canEdit'
import moment from 'moment';
import SODACharges from '../ledger/internalLedger/sodaCharges';

class Leases extends React.Component {
  state = {mode: 'lease', lease: this.props.tenant.leases.find(l => l.is_current) || this.props.tenant.leases[0]};

  componentWillReceiveProps(nextProps, nextContext) {
    const lease = nextProps.tenant.leases.find(l => l.id === this.state.lease.id) || nextProps.tenant.leases[0];
    this.selectLease(lease);
  }

  selectLease(lease) {
    this.setState({lease});
  }

  toggleModal(modal) {
    this.setState({modal});
  }

  setMode(mode) {
    this.setState({mode});
  }

  leaseBadgeStatus() {
    const {lease} = this.state;
    return (moment().isBetween(moment(lease.start_date), moment(lease.end_date)));
  }

  render() {
    const {lease, modal} = this.state;
    const {tenant} = this.props;
    return <React.Fragment>
      <Card className={`ml-3${lease.eviction ? ' alert-danger' : ''}`}>
        <CardHeader className="d-flex align-items-center py-2">
          <Col md='auto'>
            <div>Leases <Badge color={lease.eviction ? 'danger' : 'primary'}>
              {this.leaseBadgeStatus()}
            </Badge>
            </div>
          </Col>
          <Col className='ml-auto' md='auto'>
            <Nav pills>
              {tenant.leases.map(l => <NavItem key={l.id}>
                <NavLink className="py-1" active={l === lease} onClick={this.selectLease.bind(this, l)}>
                  {l.start_date} - {l.end_date}
                </NavLink>
              </NavItem>)}
            </Nav>
          </Col>
          {canEdit(['Super Admin', 'Regional']) && <Col md='auto'>
            <i id='newLease' className="fas fa-ellipsis-v ml-2 icon-hover font-sze"/>
            <UncontrolledPopover placement="bottom" target="newLease">
              <PopoverBody>
                <Button outline onClick={this.toggleModal.bind(this, 'newLease')} color='dark'>New Lease</Button>
              </PopoverBody>
            </UncontrolledPopover>
          </Col>}
        </CardHeader>
        <CardBody>
          <div className="d-flex justify-content-between">
            <div>
              {!lease.bluemoon_lease_id &&
              <a className="btn btn-outline-success" onClick={this.toggleModal.bind(this, 'captureLease')}>
                Attach BlueMoon Lease
              </a>}
              {lease.bluemoon_lease_id &&
              <a className="btn btn-outline-success" href={`/leases/${lease.id}`} target="_blank">
                View Lease Document
              </a>}
            </div>
          </div>
          <Lease lease={lease} tenant={tenant} toggleModal={this.toggleModal.bind(this)}
                 property={tenant.property} unit={tenant.unit}/>
        </CardBody>
      </Card>
      {modal === 'SODACharges' && <SODACharges toggle={this.toggleModal.bind(this)}/>}
      {modal === 'newLease' &&
      <NewLease toggle={this.toggleModal.bind(this)} lease={{...lease, tenant_id: tenant.id}}/>}
      {modal === 'eviction' &&
      <Eviction toggle={this.toggleModal.bind(this)} leaseId={lease.id} eviction={lease.eviction}/>}
      {modal === 'moveOut' && <MoveOut toggle={this.toggleModal.bind(this)} lease={lease} tenant={tenant}/>}
      {modal === 'captureLease' && <CaptureLease toggle={this.toggleModal.bind(this)} leaseId={lease.id}/>}
    </React.Fragment>
  }
}

export default Leases;
