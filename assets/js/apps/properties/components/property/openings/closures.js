import React, {Component} from 'react';
import {Row, Col, Nav, NavItem, NavLink, TabContent, TabPane, Card, CardBody, Tooltip} from 'reactstrap';
import {connect} from "react-redux";
import moment from 'moment';
import actions from '../../../actions';
import NewClosure from './newClosure';

class Closures extends Component {
  state = {
    active: 'calendar'
  }

  constructor(props) {
    super(props);
    actions.fetchClosures();
  }

  setActive(tab) {
    this.setState({...this.state, active: tab})
  }

  closuresFilter() {
    const {closures} = this.props;
    const upcoming = closures.filter(c => moment(c.date).isAfter(moment()));
    const past = closures.filter(c => moment().isAfter(moment(c.date)));
    return {upcoming, past};
  }

  toggleTooltip(target) {
    this.setState({...this.state, tooltip: target})
  }

  fullDay(start_time, end_time) {
    if (start_time === 0 && end_time === 1400) return true;
    return false;
  }

  render() {
    const {closures, property} = this.props;
    const {active, tooltip} = this.state;
    const {upcoming, past} = this.closuresFilter();
    return <Row className="mt-2">
      <Col>
        <Nav tabs>
          <NavItem>
            <NavLink className={active === "calendar" ? 'active' : ''} onClick={this.setActive.bind(this, 'calendar')}>
              Calendar <span className="badge badge-info">{closures.length}</span>
            </NavLink>
          </NavItem>
          <NavItem>
            <NavLink className={active === "new" ? 'active' : ''} onClick={this.setActive.bind(this, 'new')}>
              New Closure
            </NavLink>
          </NavItem>
        </Nav>
        <TabContent activeTab={active}>
          <TabPane tabId="calendar">
            <Row>
              <Col>
                {closures.length < 1 && <span>No dates or times set yet.</span>}
                {closures.length > 0 && <Row>
                  <Col>
                    <Card>
                      <CardBody>
                        There are {upcoming.length} Upcoming Closures
                        <hr/>
                        {upcoming.map(c => {
                          return <div key={c.id} className="d-flex justify-content-between mt-3">
                            <div className="d-flex flex-column">
                              <small>{c.admin}</small>
                              <span>{c.reason}</span>
                            </div>
                            <div className="d-flex flex-column">
                              <span onMouseEnter={this.toggleTooltip.bind(this, c.id)} id={`tooltip_${c.id}`}>{moment(c.date).format("MMM DD, YYYY")}</span>
                              {this.fullDay(c.start_time, c.end_time) ? 'Entire Day' : `${moment().startOf('day').add(c.start_time, 'm').format("h:mm")} - ${moment().startOf('day').add(c.end_time, 'm').format("h:mm")}`}
                            </div>
                            <Tooltip isOpen={tooltip === c.id} placement="top" target={`tooltip_${c.id}`} toggle={this.toggleTooltip.bind(this, null)}>
                              <div className="d-flex flex-column">
                                <span>{c.showings.length} affected tours</span>
                                {c.showings.length > 0 && c.showings.map(s => {
                                  return <span key={s.id}>
                                    <span>{s.name}</span>
                                    <span className="ml-1">{moment().startOf('day').add(s.start_time, 'm').format("h:mm")}</span>
                                  </span>
                                })}
                              </div>
                            </Tooltip>
                          </div>
                        })}
                      </CardBody>
                    </Card>
                  </Col>
                  <Col>
                    <Card>
                      <CardBody>
                        There are {past.length} Past Closures
                        <hr/>
                        {past.length > 0 && past.map(c => {
                          return <div key={c.id} className="d-flex justify-content-between mt-3">
                            <div className="d-flex flex-column">
                              <small>{c.admin}</small>
                              <span>{c.reason}</span>
                            </div>
                            <span onMouseEnter={this.toggleTooltip.bind(this, c.id)} id={`tooltip_${c.id}`}>{moment(c.date).format("MMM DD, YYYY")}</span>
                            <Tooltip isOpen={tooltip === c.id} placement="top" target={`tooltip_${c.id}`} toggle={this.toggleTooltip.bind(this, null)}>
                              <div className="d-flex flex-column">
                                <span>{c.showings.length} affected tours</span>
                                {c.showings.length > 0 && c.showings.map(s => {
                                  return <span key={s.id}>
                                    <span>{s.name}</span>
                                    <span className="ml-1">{moment().startOf('day').add(s.start_time, 'm').format("h:mm")}</span>
                                  </span>
                                })}
                              </div>
                            </Tooltip>
                          </div>
                        })}
                      </CardBody>
                    </Card>
                  </Col>
                </Row>}
              </Col>
            </Row>
          </TabPane>
          <TabPane tabId="new">
            <NewClosure property={property} toggle={this.setActive.bind(this, 'calendar')} />
          </TabPane>
        </TabContent>
      </Col>
    </Row>
  }
}

export default connect(({closures, property}) => {
  return {closures, property}
})(Closures)