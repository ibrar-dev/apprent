import React from "react";
import {connect} from "react-redux";
import {withRouter} from "react-router-dom";
import {Link} from "react-router-dom";
import moment from "moment";
import "react-dates/initialize";
import {DateRangePicker} from "react-dates";
import isInclusivelyBeforeDay from "react-dates/lib/utils/isInclusivelyAfterDay";
import {Doughnut, Pie, Bar} from "react-chartjs-2";
import {Card, CardBody, CardHeader, Row, Col, Label, Input, Button} from "reactstrap";
import icons from "../../../../components/flatIcons";
import actions from "../../actions";
import Assignments from "./assignments";
import Categories from "./categories";
import Toolbox from "./toolbox";

const barChartData = (history) => {
  //IT IS COMING IN AS AN ARRAY OF OBJECTS
  //data: [{x:'2016-12-25', y:20}, {x:'2016-12-26', y:10}]
  const data = {
    datasets: [
      {data: [], label: "Completed", backgroundColor: "#4a6220"},
      {data: [], label: "Callbacks", backgroundColor: "#ed1010"},
      {data: [], label: "Withdrawn", backgroundColor: "#eda70f"},
      {data: [], label: "Rating", backgroundColor: "#353ee8"}],
    labels: [],
  };
  history.forEach(m => {
    if (m) {
      const complete = {x: moment(m.date).format("MMMM"), y: m.complete.length};
      const callback = {x: moment(m.date).format("MMMM"), y: m.callback.length};
      const withdraw = {x: moment(m.date).format("MMMM"), y: m.withdrawn.length};
      const rating = {x: moment(m.date).format("MMMM"), y: m.rating};
      data.labels.push(moment(m.date).format("MMMM YY"));
      data.datasets[0].data.push(complete);
      data.datasets[1].data.push(callback);
      data.datasets[2].data.push(withdraw);
      data.datasets[3].data.push(rating);
    }
  });
  return data;
};

const chartData = (sortedAssignments) => {
  const data1 = [];
  const labels = Object.keys(sortedAssignments);
  const data2 = Object.values(sortedAssignments);
  data2.forEach(d => {
    data1.push(d.length)
  });
  return {
    datasets: [{
      data: data1,
      backgroundColor: ["#0fedae", "#4fa4ff", "#ffd416", "yellow", "purple", "#98c46a", "red"],
    }],
    labels: labels,
  };
};

class Show extends React.Component {
  constructor(props) {
    const tech_id = window.location.pathname.match(/techs\/(\d+)/)[1];
    super(props);
    this.state = {
      startDate: moment().subtract(30, "days"),
      endDate: moment(),
      toolbox: false,
      chart: false,
    };
    actions.fetchTechInfo(tech_id);
  }

  refreshTech() {
    actions.fetchTechInfo(this.props.tech.id);
  }

  save() {
    actions.changeTech({id: this.props.tech.id, description: this.state.desc}).then(() => {
      alert("Saved!");
    });
  }

  updateCalendar({startDate, endDate}) {
    const {tech} = this.props;
    this.setState({...this.state, startDate, endDate});
    actions.reduceAssignments(tech.assignments, startDate, endDate);
  }

  clicked(e) {
    const labels = chartData(this.props.assignments).labels;
    e.length >= 1 ? this.setState({...this.state, active: labels[(e[0]._index)]}) : this.setState({...this.state, active: null})
  }

  toggleToolbox() {
    this.setState({...this.state, toolbox: !this.state.toolbox});
  }

  toggleChart() {
    this.setState({...this.state, chart: !this.state.chart});
  }

  render() {
    const {tech, assignments, orders, history} = this.props;
    const {startDate, endDate, focusedInput, active, toolbox, chart} = this.state;
    if (tech) {
      return <>
        <div className="mb-3">
          <Link to="/techs" className="btn btn-danger mr-1">
            <i className="fas fa-arrow-left"/>
          </Link>
          <img onClick={this.toggleToolbox.bind(this)} src={icons.apprentToolbox} style={{height: 35, width: 35, cursor: "pointer"}} alt="Techs Toolbox" />
        </div>
        <Card outline>
          <CardHeader className="d-flex justify-content-between align-items-center">
            <h3 className="m-0">{tech.name}</h3>
            <div>
              <img onClick={this.refreshTech.bind(this)} src={icons.rotate} style={{height: 35, width: 35, cursor: "pointer"}} alt="Techs Toolbox" />
              {toolbox && <img className="ml-1" onClick={this.toggleChart.bind(this)} src={chart ? icons.tools :  icons.pie_chart} style={{height: 35, width: 35, cursor: "pointer"}} alt="Toggle Charts" />}
            </div>
            <div>
              <DateRangePicker startDate={startDate}
                               endDate={endDate}
                               startDateId="start-timecard-date-id"
                               endDateId="end-timecard-date-id"
                               focusedInput={focusedInput}
                               minimumNights={0}
                               small
                               disabled={toolbox}
                               isOutsideRange={day => isInclusivelyBeforeDay(day, moment().add(1, "days"))}
                               onFocusChange={focusedInput => this.setState({focusedInput})}
                               onDatesChange={this.updateCalendar.bind(this)}/>
            </div>
          </CardHeader>
          <CardBody>
            <Row>
              <Col lg={9} md={12}>
                {!toolbox && <>
                  <Row>
                    <Col lg={6} md={12} className="d-flex flex-column justify-content-center">
                      <Doughnut data={chartData(assignments)} getElementAtEvent={this.clicked.bind(this)} />
                    </Col>
                    <Col lg={6} md={12} className="d-flex flex-column justify-content-center">
                      {/*<Polar data={chartData(assignments)} />*/}
                      {history && <Bar data={barChartData(history)} />}
                    </Col>
                  </Row>
                  <Row>
                    <Col sm={12}>
                      <Assignments tech={tech} assignments={assignments} orders={orders} active={active} />
                    </Col>
                  </Row>
                </>}
                {toolbox && <Toolbox items={tech.toolbox} chart={chart} dates={{startDate, endDate}} />}
              </Col>
              <Col lg={3} md={12}>
                <div className="d-flex justify-content-between">
                  <h4>{tech.category_ids.length} Categories</h4>
                  <Button onClick={() => actions.selectAllCategories(tech.id)} outline color="info">Select All</Button>
                </div>
                <Categories />
              </Col>
            </Row>
          </CardBody>
        </Card>
      </>
    } else {
      return null
    }
  }
}

export default withRouter(connect(({tech, assignments, orders, history}) => {
  return {tech, assignments, orders, history}
})(Show));