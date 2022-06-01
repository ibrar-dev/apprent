import React from 'react';
import {Card, CardHeader, CardBody, Nav, NavItem, NavLink, Row, Col} from 'reactstrap';
import NewEmail from './newEmail';
import SentEmails from './sentEmails';

class Mailer extends React.Component {
  state = {active: 'all'};

  setTab(val) {
    this.setState({...this.state, active: val})
  }

  render() {
    const {tenant} = this.props;
    const {active} = this.state;
    return <React.Fragment>
      <Card className={`ml-3`}>
        <CardHeader className="d-flex justify-content-between align-items-center">
          <div>Email for {tenant.first_name} {tenant.last_name}</div>
          <Nav pills>
            <NavItem className="">
              <NavLink active={active === "all"} onClick={this.setTab.bind(this, "all")}
                       className="btn-outline-info py-1 px-2">
                Sent Emails
              </NavLink>
            </NavItem>
            <NavItem>
              <NavLink active={active === "new"} onClick={this.setTab.bind(this, "new")}
                       className="btn-outline-info py-1 px-2 ml-3">
                New Email
              </NavLink>
            </NavItem>
          </Nav>
        </CardHeader>
        {!tenant.email && <CardBody>
          <p>{tenant.first_name} does not have an email in the system. To unlock this area please go into their profile
            and add a valid email.</p>
        </CardBody>}
        {tenant.email && <CardBody>
          <Row>
            <Col>
              {active === 'all' && <SentEmails emails={tenant.emails}/>}
              {active === 'new' && <NewEmail tenant={tenant}/>}
            </Col>
          </Row>
        </CardBody>}
      </Card>
    </React.Fragment>
  }
}

export default Mailer