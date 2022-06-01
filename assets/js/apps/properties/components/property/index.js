import React from 'react';
import {Nav, NavItem, NavLink, Card, CardBody, Badge} from 'reactstrap';
import Location from './location';
import Settings from './settings';
import Accounts from './accounts';
import Documents from './documents'
import PhoneNumbers from './phoneNumbers';
import Integrations from './integrations';
import Openings from './openings';
import APIKeys from './apiKeys';
import FloorPlans from './floorPlans';
import canEdit from '../../../../components/canEdit';

const key = {
  loc: Location,
  set: Settings,
  acc: Accounts,
  doc: Documents,
  pho: PhoneNumbers,
  int: Integrations,
  ope: Openings,
  api: APIKeys,
  fps: FloorPlans
};


class Property extends React.Component {
  state = {tab: 'loc'};

  setTab(tab) {
    this.setState({tab});
  }

  _navLink(field, label, active, alert) {
    return <NavItem>
      <NavLink active={active === field} onClick={this.setTab.bind(this, field)}>
        {label} {alert && <Badge color="danger">!</Badge>}
      </NavLink>
    </NavItem>;
  }

  render() {
    const {property} = this.props;
    const {tab} = this.state;
    const Active = key[tab];
    return <React.Fragment>
      <Nav tabs className="pl-3">
        {this._navLink('loc', 'Location', tab)}
        {this._navLink('set', 'Settings', tab)}
        {canEdit(['Super Admin']) && this._navLink('int', 'Integrations', tab)}
        {this._navLink('acc', 'Accounts', tab)}
        {this._navLink('doc', 'Documents', tab)}
        {this._navLink('pho', 'Phone Lines', tab)}
        {this._navLink('ope', 'Showing Hours', tab)}
        {this._navLink('api', 'API Keys', tab)}
        {this._navLink('fps', 'Floor Plans', tab)}
      </Nav>
      <Card className="rounded-0 border-top-0 border-left-0 m-0 flex-auto">
        <CardBody>
          <Active property={property}/>
        </CardBody>
      </Card>
    </React.Fragment>
  }
}

export default Property;
