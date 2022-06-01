import React from 'react';
import {Card, CardBody, Nav, NavItem, NavLink} from 'reactstrap';
import Prizes from './prizes';
import Types from './types';

const tabs = {
  prizes: Prizes,
  types: Types
};

class Rewards extends React.Component {
  state = {activeTab: 'types'};

  setTab(tab) {
    this.setState({activeTab: tab});
  }

  render() {
    const {activeTab} = this.state;
    const Component = tabs[activeTab];
    return <div>
      <Nav tabs>
        <NavItem>
          <NavLink active={activeTab === 'types'} onClick={this.setTab.bind(this, 'types')}>
            <h4 className="m-0">Categories</h4>
          </NavLink>
        </NavItem>
        <NavItem>
          <NavLink active={activeTab === 'prizes'} onClick={this.setTab.bind(this, 'prizes')}>
            <h4 className="m-0">Prizes</h4>
          </NavLink>
        </NavItem>
      </Nav>
      <Card className="border-top-0 rounded-0">
        <CardBody>
          <Component/>
        </CardBody>
      </Card>
    </div>;
  }
}

export default Rewards;