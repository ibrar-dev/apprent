import React, {Component} from 'react';
import {Button, ButtonGroup} from 'reactstrap';
import Occupant from './occupant';
import NewTenant from './newTenant';
import ScreeningModal from './screeningModal';

class Occupants extends Component {
  state = {occupants: this.props.lease.occupants, occupantId: (this.props.lease.occupants[0] || {}).id};

  componentWillReceiveProps(nextProps, nextContext) {
    this.setState({occupants: nextProps.lease.occupants});
  }

  viewPerson(occupantId) {
    this.setState({occupantId});
  }

  toggleNewTenant() {
    this.setState({newTenant: !this.state.newTenant});
  }

  viewScreening(s) {
    this.setState({screeningId: s});
  }

  render() {
    const {tenantId, lease, tenants} = this.props;
    const {occupants, occupantId, newTenant, screeningId} = this.state;
    const screening = lease.screenings.find(s => s.id === screeningId);
    return <div className="mt-3">
      <h3>Other Tenants</h3>
      <div className="">
        {tenants.map(t => {
          return <a key={t.id} className="text-info mr-2" href={`/tenants/${t.id}`}>{t.first_name} {t.last_name}</a>
        })}
        <div className="my-2">
          <Button color="success" onClick={this.toggleNewTenant.bind(this)}>
            Add/Screen New Tenant
          </Button>
        </div>
      </div>
      <h3>Pending Screenings</h3>
      <div className="">
        {lease.screenings.map(s => {
          return <a key={s.id} className="text-info mr-2" onClick={this.viewScreening.bind(this, s.id)}>
            {s.first_name} {s.last_name}
          </a>
        })}
      </div>
      <h3 className="mt-4">Occupants</h3>
      <ButtonGroup>
        {occupants.length > 0 && occupants.map(o => {
          return <Button key={o.id} color="info" outline={o.id !== occupantId}
                         onClick={this.viewPerson.bind(this, o.id)}>
            {o.first_name} {o.last_name}
          </Button>
        })}
        <Button color="info" outline={!!occupantId} onClick={this.viewPerson.bind(this, null)}>
          New Occupant
        </Button>
      </ButtonGroup>
      <div className="mt-3">
        <Occupant occupant={occupants.find(o => o.id === occupantId)}
                  leaseId={lease.id} tenantId={tenantId}/>
      </div>
      {newTenant && <NewTenant toggle={this.toggleNewTenant.bind(this)} leaseId={lease.id}/>}
      {screening && <ScreeningModal toggle={this.viewScreening.bind(this)} screening={screening}/>}
    </div>;
  }
}

export default Occupants;