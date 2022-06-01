import React from 'react';
import {Nav, NavItem, NavLink} from 'reactstrap';
import TenantProfile from './profile';
import Pets from './pets';
import Vehicles from './vehicles';

const key = {
  profile: TenantProfile,
  pets: Pets,
  vehicles: Vehicles
};

class Profile extends React.Component {
  state = {mode: 'profile'};

  setMode(mode) {
    this.setState({mode});
  }

  render() {
    const {mode} = this.state;
    const Screen = key[mode];
    return <div className="position-relative px-4">
      <Nav tabs>
        <NavItem>
          <NavLink active={mode === 'profile'} onClick={this.setMode.bind(this, 'profile')}>Profile</NavLink>
        </NavItem>
        <NavItem>
          <NavLink active={mode === 'pets'} onClick={this.setMode.bind(this, 'pets')}>Pets</NavLink>
        </NavItem>
        <NavItem>
          <NavLink active={mode === 'vehicles'} onClick={this.setMode.bind(this, 'vehicles')}>Vehicles</NavLink>
        </NavItem>
      </Nav>
      <Screen tenant={this.props.tenant}/>
    </div>;
  }
}

export default Profile;