import React, {Fragment} from 'react';
import {connect} from 'react-redux';
import {Row, Col, Card, CardHeader, CardBody, Collapse} from 'reactstrap';
import 'react-dates/initialize';
import {DateRangePicker} from "react-dates";
import isInclusivelyBeforeDay from "react-dates/lib/utils/isInclusivelyAfterDay";
import moment from 'moment';
import {Pie, Doughnut} from 'react-chartjs-2';
import actions from '../../actions';
import icons from '../../../../components/flatIcons';
import {titleize} from '../../../../utils';

const dataReducer = (workOrders) => {
  let shortenedOrders = [];
  let categories = {};
  let techs = {};
  workOrders.forEach(wo => {
    if (wo.assignments[0] && wo.assignments[0].status === 'completed') {
      shortenedOrders.push({id: wo.id, completion_time: (moment(wo.assignments[0].completed_at).diff(moment(wo.submitted), 'days', true))})
    };
    if (categories[wo.category]) {
      categories[wo.category] ++
    } else {
      categories[wo.category] = 1
    };
    if (wo.assignments) {
      wo.assignments.forEach(a => {
        if (techs[a.tech]) {
          techs[a.tech] ++
        } else {
          techs[a.tech] = 1
        }
      })
    };
  });
  const avgCompletionTime = (shortenedOrders.reduce((sum, wo) => sum + wo.completion_time, 0).toFixed(3) / shortenedOrders.length);
  return {avgTime: avgCompletionTime, categories: categories, techs: techs};
};

const categoriesChartData = (categories) => {
  let labels = Object.keys(categories);
  let data1 = Object.values(categories);
  let data = {
    datasets: [{
      data: data1,
      backgroundColor: ["#0fedae", "#260CE8", "#FF0000", "#E8A80C", "#3AFF0D", "#4A6220", "#E8990C", "#4C0CE8", "#0DECFF"]
    }],
    labels: labels
  };
  return data;
};

class WorkOrders extends React.Component {
  state = {
    dates: {
      startDate: moment('2018-04-01T00:00:00.000'),
      endDate: moment(),
    },
    details: true
  };

  componentWillMount() {
    actions.fetchWorkOrders(this.props.tenant.tenant_id);
  }

  getStatus(assignment) {
    if (!assignment || (["rejected", "withdrawn", "revoked"].includes(assignment.status))) return "Open";
    return titleize(assignment.status)
  }

  setActiveOrder(id) {
    this.state.activeOrderId === id ? this.setState({activeOrderId: null}) : this.setState({...this.state, activeOrderId: id});
  }

  noteToDisplay(wo) {
    const assignment = wo.assignments[0];
    const {no_access, parts} = wo;
    if (!assignment) return "Unfortunately we have not had a chance to work on this request yet";
    if (assignment.status === 'completed') return <React.Fragment><span>Service Request was completed by {assignment.tech} on {moment.utc(assignment.completed_at).local().format("MMMM Do, YYYY")} at {moment.utc(assignment.completed_at).local().format("hh:mm a")}. Tech Comment: {assignment.tech_comments ? assignment.tech_comments : ''}</span></React.Fragment>;
    if (no_access.length >= 1) return <React.Fragment><span>Our tech {no_access[0].tech_name ? no_access[0].tech_name : 'N/A'} tried to enter the unit at {moment.utc(no_access[0].time).local().format("hh:mm a")} on {moment.utc(no_access[0].time).local().format("MMMM Do, YYYY")}. This was attempt #{no_access.length}</span></React.Fragment>;
    if (parts.length >= 1 && ["pending", "ordered"].includes(parts[0].status)) return <span>We are waiting on a part ({parts[0].name}) to complete this order. The part is currently {parts[0].status}</span>;
    if (["rejected", "withdrawn", "revoked"].includes(assignment.status)) return `The technician ${assignment.tech} had to withdraw from the request.  Tech Comment: ${assignment.tech_comments ? assignment.tech_comments : ''}`;
  }

  updateCalendar({startDate, endDate}) {
    this.setState({...this.state, dates: {startDate, endDate}})
  }

  filteredOrders() {
    const {dates: {startDate, endDate}} = this.state;
    const {workOrders} = this.props;
    return workOrders.filter(wo => moment.utc(wo.submitted).isBetween(startDate, endDate));
  }

  toggleDetails() {
    this.setState({...this.state, details: !this.state.details})
  }

  nameToDisplay(note){
    if(note.admin) return note.admin;
    if(note.tenant) return note.tenant;
    if(note.tech) return note.tech;
  }

  techNotes(wo){
    let i = 0;
    return wo.assignments.map(a => {
      if(a.tech_comments){
          i += 1;
          return <React.Fragment key={a.id}>
              {/*<span>{assignment.tech_commenttech}</span>*/}
              <span>{i}. {a.tech_comments}</span>
              <span><b>-{a.tech}</b></span>
          </React.Fragment>
      }
    });
  }

  render() {
    const {activeOrderId, dates, focusedInput, details} = this.state;
    const workOrders = this.filteredOrders();
    const {avgTime, categories, techs} = dataReducer(workOrders);
    return <div className="px-4">
      {workOrders && <Row>
        <Col>
          <Card>
            <CardHeader className="d-flex justify-content-between">
              <span>Detailed Stats</span>
              <div>
                <DateRangePicker startDate={dates.startDate}
                                 endDate={dates.endDate}
                                 startDateId="start-timecard-date-id"
                                 endDateId="end-timecard-date-id"
                                 focusedInput={focusedInput}
                                 minimumNights={0}
                                 small
                                 isOutsideRange={day => isInclusivelyBeforeDay(day, moment().add(1, 'days'))}
                                 onFocusChange={focusedInput => this.setState({focusedInput})}
                                 onDatesChange={this.updateCalendar.bind(this)}/>
                <span className="ml-5"><i className={`fas fa-caret-${details ? 'down' : 'right'}`} onClick={this.toggleDetails.bind(this)} /></span>
              </div>
            </CardHeader>
            <Collapse isOpen={details}>
              <CardBody>
                <Row>
                  <Col>
                    <p>Average Completion Time: <b>{avgTime ? avgTime : 'N/A'}</b> days</p>
                  </Col>
                </Row>
                <Row>
                  <Col sm={12} md={6}>
                    <Pie data={categoriesChartData(categories)} options={{title: {text: "Categories", display: true}}} />
                  </Col>
                  <Col  sm={12} md={6}>
                    <Doughnut data={categoriesChartData(techs)} options={{title: {text: "Techs", display: true}}} />
                  </Col>
                </Row>
              </CardBody>
            </Collapse>
          </Card>
        </Col>
      </Row>}
      <Row>
        <Col sm={12}>
          {workOrders && workOrders.map(wo => {
            return <Card key={wo.id} className="">
              <CardHeader className="d-flex justify-content-between" onClick={this.setActiveOrder.bind(this, wo.id)}>
                <span>{wo.category} | {wo.subcategory}</span>
                <span>Status: {this.getStatus(wo.assignments[0])}</span>
              </CardHeader>
              <Collapse isOpen={wo.id === activeOrderId}>
                <CardBody>
                  <Row>
                    <Col className="d-flex flex-column">
                        <span>Note: <b>{this.noteToDisplay(wo)}</b></span>
                      <span>Reference: {wo.ticket}</span>
                    </Col>
                      <Col className="d-flex flex-column align-items-end">
                          <img className="img-fluid" style={{width: 50, height: 50}} src={wo.entry_allowed ? icons.entry_allowed : icons.entry_not_allowed} alt="Entry Allowed or Entry Not Allowed"/>
                          <img className="img-fluid" style={{width: 50, height: 50}} src={wo.has_pet ? icons.has_pet : icons.no_pet} alt="Has Pet or Does Not Have A Pet"/>
                      </Col>
                  </Row>
                    {wo.notes.length && <Row>
                        <Col className="d-flex flex-column">
                            <span><b>Notes</b></span>
                            {wo.notes.map((note, i) => <React.Fragment key={i}>
                                <span><b>{moment(note.inserted_at).format("MM/DD/YYYY")}</b></span>
                                <span>{note.text}</span>
                                <span><b>-{this.nameToDisplay(note)}</b></span>
                            </React.Fragment>)}
                          <hr/>
                            <span><b>Tech Comments</b></span>
                            {this.techNotes(wo)}
                        </Col>
                    </Row>}
                </CardBody>
              </Collapse>
            </Card>
          })}
        </Col>
      </Row>
    </div>
  }
}

export default connect(({tenant, workOrders}) => {
  return {tenant, workOrders}
})(WorkOrders);