import React from 'react';
import {Row, Col, Card, CardHeader, CardBody, Input, InputGroup, InputGroupAddon, Button, Nav, NavItem, NavLink, TabContent, TabPane} from 'reactstrap';
import moment from 'moment';
import action from '../../actions';
import classnames from 'classnames';

class Interactions extends React.Component {
  state = {
    description: '',
    filter: '',
    activeTab: "all"
  };

  updateDescription(e) {
    this.setState({...this.state, description: e.target.value});
  }

  updateFilter(e) {
    this.setState({...this.state, filter: e.target.value.toLowerCase()});
  }

  saveInteraction() {
    let currentLease = this.props.tenant.leases.filter(l => l.is_current)[0];
    if (!currentLease) currentLease = this.props.tenant.leases[0];
    action.saveInteraction(this.props.tenant, this.state.description, currentLease.property.id);
    this.setState({...this.state, description: ''})
  }

  setTab(tab){
    this.setState({...this.state, activeTab: tab});
  }

  render() {
    const {description, filter} = this.state;
    const {tenant} = this.props;
    return <React.Fragment>
      <Card className="ml-3">
        <CardHeader>
          Record a new Tenant Visit
        </CardHeader>
        <CardBody>
          <Row>
            <Col sm={7}>
              <InputGroup>
                <Input
                  onChange={this.updateDescription.bind(this)}
                  value={description}
                  placeholder="Describe tenant's visit(min 10 characters)"/>
                <InputGroupAddon addonType="append">
                  <Button outline
                          color="info"
                          disabled={!description || description.length < 10}
                          onClick={this.saveInteraction.bind(this)}>Save</Button>
                </InputGroupAddon>
              </InputGroup>
            </Col>
            <Col sm={5}>
              <Input onChange={this.updateFilter.bind(this)}
                     value={filter}
                     placeholder="Search Visits"/>
            </Col>
          </Row>
        </CardBody>
      </Card>
      <Col>
      <Nav tabs>
        <NavItem>
          <NavLink onClick={this.setTab.bind(this, "all")} className={classnames({ active: this.state.activeTab === "all"})}>All</NavLink>
        </NavItem>
        <NavItem>
          <NavLink onClick={this.setTab.bind(this, "res_int")} className={classnames({ active: this.state.activeTab === "res_int"})}>Resident Interaction</NavLink>
        </NavItem>
        <NavItem>
          <NavLink onClick={this.setTab.bind(this, "dq")} className={classnames({ active: this.state.activeTab === "dq"})}>Delinquency Memo</NavLink>
        </NavItem>
        <NavItem>
          <NavLink onClick={this.setTab.bind(this, "application")} className={classnames({ active: this.state.activeTab === "application"})}>Application Memos</NavLink>
        </NavItem>
      </Nav>
      <TabContent className="rounded-0 border-top-0 m-0 flex-auto" activeTab={this.state.activeTab}>
        <TabPane tabId="all">
          <Row className='ml-0'>
            <Col>
              {tenant.visits.map(v => v.description.toLowerCase().includes(filter) ? <Card key={v.id}>
                <CardHeader>On <strong>{moment(v.inserted_at).format('dddd MMMM Do YYYY')}, {tenant.first_name}</strong> interacted
                  with <strong>{v.admin}</strong></CardHeader><CardBody>{v.description}</CardBody></Card> : null)}
            </Col>
          </Row>
        </TabPane>
        <TabPane tabId="res_int">
          <Row className='ml-0'>
            <Col>
              {tenant.visits.filter((v) => !v.delinquency).map(v => v.description.toLowerCase().includes(filter) ? <Card key={v.id}>
                <CardHeader>On <strong>{moment(v.inserted_at).format('dddd MMMM Do YYYY')}, {tenant.first_name}</strong> interacted
                  with <strong>{v.admin}</strong></CardHeader><CardBody>{v.description}</CardBody></Card> : null)}
            </Col>
          </Row>
        </TabPane>
        <TabPane tabId="dq">
          <Row className='ml-0'>
            <Col>
              {tenant.visits.filter((v) => v.delinquency).map(v => v.description.toLowerCase().includes(filter) ? <Card key={v.id}>
                <CardHeader>On <strong>{moment(v.inserted_at).format('dddd MMMM Do YYYY')}, {tenant.first_name}</strong> interacted
                  with <strong>{v.admin}</strong></CardHeader><CardBody>{v.description}</CardBody></Card> : null)}
            </Col>
          </Row>
        </TabPane>
        <TabPane tabId="application">
          <Row className='ml-0'>
            <Col>
              {
                tenant.application_memos.map(m => (
                  <Card key={m.id}>
                    <CardHeader>
                      On
                      <strong className="mx-1">{moment(m.inserted_at).format('dddd MMMM Do YYYY')}</strong>
                      memo by
                      <strong className="ml-1">{m.admin_name}</strong>
                    </CardHeader>
                    <CardBody>{m.note}</CardBody>
                  </Card>
                ))
              }
            </Col>
          </Row>
        </TabPane>
      </TabContent>
      </Col>
    </React.Fragment>;
  }
}

export default Interactions;
