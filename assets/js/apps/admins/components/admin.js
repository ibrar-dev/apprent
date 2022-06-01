import React, {useState, useEffect} from "react";
import {withRouter} from "react-router-dom";
import {
  Container,
  TabContent,
  TabPane,
  Nav,
  NavItem,
  NavLink,
  Row,
  Col,
} from "reactstrap";
import classnames from "classnames";
import ActionsTable from "./show/actionsTable";
import Info from "./show/info";
import Roles from "./show/roles";
import Entities from "./show/entities";
import Email from "./show/email";
import Password from "./show/password";
import actions from "../actions";

const TabDisplay = ({id, display}) => (
  <TabPane tabId={id}>
    <Row>
      <Col sm="12">
        {display}
      </Col>
    </Row>
  </TabPane>
);

const NavTab = ({id, label, toggle, activeTab}) => (
  <NavItem>
    <NavLink
      className={classnames({active: activeTab === id})}
      onClick={() => { toggle(id); }}
    >
      {label}
    </NavLink>
  </NavItem>
);

const Admin = ({match}) => {
  const {params: {id: adminId}} = match;
  const [activeTab, setActiveTab] = useState("info");

  useEffect(() => {
    actions.fetchAdminInfo(adminId);
  }, []);

  const toggle = (tab) => {
    if (activeTab !== tab) setActiveTab(tab);
  };

  return (
    <Container>
      <Nav tabs>
        <NavTab id="info" label="Info" toggle={toggle} activeTab={activeTab} />
        <NavTab id="password" label="Password" toggle={toggle} activeTab={activeTab} />
        <NavTab id="roles" label="Roles" toggle={toggle} activeTab={activeTab} />
        <NavTab id="entities" label="Entities" toggle={toggle} activeTab={activeTab} />
        <NavTab id="email" label="Email" toggle={toggle} activeTab={activeTab} />
        <NavTab id="actions" label="Actions" toggle={toggle} activeTab={activeTab} />
      </Nav>
      <TabContent activeTab={activeTab}>
        <TabDisplay id="info" display={<Info />} />
        <TabDisplay id="password" display={<Password />} />
        <TabDisplay id="roles" display={<Roles />} />
        <TabDisplay id="entities" display={<Entities />} />
        <TabDisplay id="email" display={<Email />} />
        <TabDisplay id="actions" display={<ActionsTable />} />
      </TabContent>
    </Container>
  );
};

export default withRouter(Admin);
