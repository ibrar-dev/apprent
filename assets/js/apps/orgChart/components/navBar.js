import React, { Component } from 'react';
import {Nav, NavItem, NavLink, TabContent, TabPane} from 'reactstrap'
import OrgChart from './org_chart.js'
import Rules from './rules.js'
import classnames from 'classnames';

const canEdit = (role) => {
    return (window.roles.includes("Super Admin") || window.roles.includes(role));
};

class NavBar extends Component {

  state={activeTab: "permissions"}

  changeTab(tab){
    this.setState({activeTab: tab})
  }

  render() {
    return <>
      <Nav tabs>
        <NavItem>
          <NavLink className={classnames({active: this.state.activeTab === "permissions"})} onClick={this.changeTab.bind(this, "permissions")}>
              Permissions
          </NavLink>
        </NavItem>
        {canEdit("Super Admin") && <NavItem>
          <NavLink className={classnames({active: this.state.activeTab === "rules"})} onClick={this.changeTab.bind(this, "rules")}>
              Rules
          </NavLink>
        </NavItem>}
    </Nav>
    {this.state.activeTab === "permissions" && <Permissions/>}
    {this.state.activeTab === "rules" && <Rules/>}
  </>
  }

}

export default NavBar;
