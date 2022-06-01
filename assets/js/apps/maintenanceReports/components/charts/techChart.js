import React, {Component} from "react";
import {Space, Avatar} from "antd";
import {
  Button,
  Row,
  Col,
  Dropdown,
  DropdownToggle,
  DropdownMenu,
  Card,
  CardTitle,
  CardSubtitle,
  CardBody,
  Collapse
} from "reactstrap";
import Select from "../../../../components/select";
import MultiPropertySelect from "../../../../components/multiPropertySelect"
import "react-dates/initialize";
import {DateRangePicker} from "react-dates";
import isInclusivelyBeforeDay from "react-dates/lib/utils/isInclusivelyAfterDay";
import moment from "moment";

const properties = window.properties;

// Returns avatar image as image or the tech's initials
function avatarToDisplay(tech) {
  if (tech.image) return <Avatar src={tech.image} />
  return <Avatar>{tech.name.split(" ").map(n => n[0]).join("").toUpperCase()}</Avatar>
}

class TechChart extends Component {
  constructor(props) {
    super(props);
    this.state = {
      startDate: moment().startOf("month"),
      endDate: moment(),
      techList: [],
      minTechList: this.props.maintenanceTechs.list,
      detailedTechs: this.props.maintenanceTechs.detailed,
      selectedProperties: []
    };

    this.onPropertySelectChange = this.onPropertySelectChange.bind(this)
    this.selectAllTechsForProperties = this.selectAllTechsForProperties.bind(this)
    this.setSelectedTechs = this.setSelectedTechs.bind(this)
    this.setDates = this.setDates.bind(this)
    this.toggleTotals = this.toggleTotals.bind(this)
  }

  // Given props, build state
  static getDerivedStateFromProps(props, state) {
    let newState = state;
    newState.minTechList = props.maintenanceTechs.list;
    newState.detailedTechs = props.maintenanceTechs.detailed;
    return newState;
  }

  toggleTechMenu() {
    this.setState({...this.state, techMenuOpen: !this.state.techMenuOpen});
  }

  setDates({startDate, endDate}) {
    this.setState({...this.state, startDate, endDate}, this.fetchInfo);
  }

  // value is an array of integer primary key IDs of techs
  setSelectedTechs({target: {value}}) {
    this.setState({...this.state, techList: value}, this.fetchInfo);
  }

  onPropertySelectChange(ids) {
    this.setSelectedProperties(ids)
  }

  setSelectedProperties(ids) {
    this.setState({...this.state, selectedProperties: ids}, this.fetchInfo)
  }

  techList(e) {
    const {techList} = this.state;
    const intVal = parseInt(e.target.value);
    if (techList.includes(intVal)) {
      techList.splice(techList.indexOf(intVal), 1);
    } else {
      techList.push(intVal);
    }
    this.setState({...this.state, techList}, this.fetchInfo);
  }

  fetchInfo() {
    const {techList, startDate, endDate, selectedProperties} = this.state;

    let propertyIds

    if (selectedProperties.length > 0) {
      propertyIds = selectedProperties
    } else {
      propertyIds = properties.map((property) => property.id)
    }

    if (techList.length > 0 && startDate && endDate && propertyIds) {
      this.props.updateInfo(techList, startDate, endDate, propertyIds);
    } else {
      return;
    }
  }

  toggleTotals() {
    this.setState({...this.state, totals: !this.state.totals});
  }

  calculateTotal(detailed) {
    const all = detailed.reduce((acc, t) => {
      return acc.concat(t.assignments);
    }, []);

    const totalPunches = detailed.reduce((acc, t) => {
      return acc + t.punches.length
    }, 0);

    const total = all.length;
    const completed = all.filter(a => a.status === "completed");
    const callbacks = all.filter(a => a.status === "callback");
    const withdrawn = all.filter(a => a.status === "withdrawn");
    const avgTime = this.calculateAverageTime(all);
    const avgRating = this.calculateAverageRating(all);

    return {total, completed, callbacks, withdrawn, avgTime, avgRating, totalPunches}
  }

  calculateAverageTime(assignments) {
    const completed = assignments.filter(a => a.completed_at);
    if (completed.length === 0) {
      return 0
    } else {
      const total = completed.reduce(
        (acc, a) => moment(a.completed_at).diff(moment(a.inserted_at)) + acc, 0
      ) / completed.length;

      return moment.duration(total).asDays().toFixed(1);
    }
  }

  calculateAverageRating(assignments) {
    const rated = assignments.filter(a => a.rating);
    if (rated.length === 0) {
      return 0
    } else {
      return rated.reduce((acc, a) => a.rating + acc, 0) / rated.length
    }
  }

  //Displays a "N/A" if there are no ratings for a particular tech. Otherwise shows a rating
  ratingCheck(tech){
    if (this.calculateAverageRating(tech.assignments) === 0) {
      return <span> N/A </span>
    } else {
      return <span><b>{this.calculateAverageRating(tech.assignments).toFixed(1)}</b> / 5</span>
    }
  }

  showTechDetails(tech) {
    const completed = tech.assignments.filter(a => a.status === "completed");
    const callbacks = tech.assignments.filter(a => a.status === "callback");
    const withdrawals = tech.assignments.filter(a => a.status === "withdrawn");
    return <div className="d-flex flex-column">
      <div className="d-flex justify-content-between">
        <span>Total</span>
        <span>{tech.assignments.length}</span>
      </div>
      <div className="d-flex justify-content-between">
        <span>Completed</span>
        <span>{completed.length}</span>
      </div>
      <div className="d-flex justify-content-between">
        <span>Punches</span>
        <span>{tech.punches ? tech.punches.length : ""}</span>
      </div>
      <div className="d-flex justify-content-between">
        <span>Callbacks</span>
        <span>{callbacks.length}</span>
      </div>
      <div className="d-flex justify-content-between">
        <span>Withdrawals</span>
        <span>{withdrawals.length}</span>
      </div>
      <div className="d-flex justify-content-between">
        <span>Avg Completion Time</span>
        <span><b>{this.calculateAverageTime(tech.assignments)}</b> days</span>
      </div>
      <div className="d-flex justify-content-between">
        <span>Avg Rating</span>
        {this.ratingCheck(tech)}
      </div>
    </div>
  }

  selectionDescriptor(techs, properties) {
    let techString = "technicians"
    if (techs.length == 1) {
      techString = "technician"
    }

    let propertyString = "properties"
    if (properties.length == 1) {
      propertyString = "property"
    }

    let propertyCount = "all"
    if (properties.length > 0) {
      propertyCount = properties.length
    }

    return `Showing statistics for the ${techs.length} ${techString} selected and their work at ${propertyCount} selected ${propertyString}`
  }

  // When the "Select all Techs" button is clicked, we select all techs
  // available for the given properties. If no properties are selected we select
  // no techs.
  selectAllTechsForProperties() {
    const {selectedProperties, minTechList} = this.state

    const filteredTechs = minTechList.filter((tech) => (
      tech.property_ids.filter((id) => selectedProperties.includes(id)).length > 0
    )).map((tech) => tech.id)

    const {startDate, endDate} = this.state;
    this.setState({...this.state, techList: filteredTechs});
    if (filteredTechs.length >= 1) {
      this.props.updateInfo(filteredTechs, startDate, endDate, selectedProperties);
    }
  }

  render() {
    const {maintenanceTechs, updateInfo} = this.props;
    const {
      detailedTechs,
      endDate,
      focusedInput,
      minTechList,
      selectedProperties,
      startDate,
      techList,
      totals,
    } = this.state;

    const {detailed} = maintenanceTechs;
    const calculatedTotals = this.calculateTotal(detailed);

    let filteredTechs = []

    // If we have properties selected, we only make selectable the set of techs
    // available at those properties. If we have no properties selected,
    // everyone is on the table. We do not de-select already selected
    // technicians.
    if (selectedProperties.length > 0) {
      filteredTechs = minTechList.filter(
        (tech) => (
          techList.includes(tech.id) ||
          tech.property_ids.filter((id) => selectedProperties.includes(id)).length > 0
        )
      )
    } else {
      filteredTechs = minTechList
    }

    return <>
      <Row className="mb-3">
        <Col lg={10}>
          <MultiPropertySelect
            className={"flex-fill w-100"}
            onChange={this.onPropertySelectChange}
          />
        </Col>
        <Col lg={2} className="d-flex justify-content-lg-end mt-2 mt-lg-0 ">
          <DateRangePicker
            startDate={startDate}
            endDate={endDate}
            startDateId="start-timecard-date-id"
            endDateId="end-timecard-date-id"
            focusedInput={focusedInput}
            minimumNights={0}
            small
            isOutsideRange={day => isInclusivelyBeforeDay(day, moment().add(1, "days"))}
            onFocusChange={focusedInput => this.setState({focusedInput})}
            onDatesChange={this.setDates}
          />
        </Col>
      </Row>
      <Row>
        <Col lg={8}>
          <div style={{minWidth: "100%"}}>
            <Select
              value={techList}
              multi
              className="w-100"
              placeholder="Select some technicians to see their stats"
              options={filteredTechs.map(t => {
                return {value: t.id, label: t.name};
              })}
              onChange={this.setSelectedTechs}
            />
          </div>
        </Col>
        <Col lg={4}>
          <Button
            disabled={selectedProperties.length == 0}
            outline
            color="info"
            onClick={this.selectAllTechsForProperties}
          >
            All Techs for Selected Properties
          </Button>
        </Col>
      </Row>
      <Row className="mt-2">
        <Col className="d-flex justify-content-between">
          <span>{this.selectionDescriptor(detailed, selectedProperties)}</span>
        </Col>
      </Row>
      <Row className="my-2">
        <Col>
          <Button
            active={totals}
            onClick={this.toggleTotals}
            outline
            color="info"
            disabled={detailed.length == 0}
          >
            {totals ? "Hide Stats Summary" : "Show Stats Summary"}
          </Button>
        </Col>
      </Row>
      <Collapse isOpen={totals}>
        <Row className="mt-1">
          <Col sm={12}>
            <Card body>
              <Row>
                <Col sm={4} className="d-flex justify-content-between">
                  <span>Total</span>
                  <span>
                    {calculatedTotals.total} | <b>{(calculatedTotals.total / techList.length).toFixed(1)}</b>
                  </span>
                </Col>
                <Col sm={4} className="d-flex justify-content-between">
                  <span>Completed</span>
                  <span>
                    {calculatedTotals.completed.length} | <b>{(calculatedTotals.completed.length / techList.length).toFixed(1)}</b>
                  </span>
                </Col>
                <Col sm={4} className="d-flex justify-content-between">
                  <span>Average Completion Time</span>
                  <span><b>{calculatedTotals.avgTime || "None Completed"}</b> days</span>
                </Col>
              </Row>
              <Row>
                <Col sm={4} className="d-flex justify-content-between">
                  <span>Withdrawn</span>
                  <span>
                    {calculatedTotals.withdrawn.length} | <b>{(calculatedTotals.withdrawn.length / techList.length).toFixed(1)}</b>
                  </span>
                </Col>
                <Col sm={4} className="d-flex justify-content-between">
                  <span>Callbacks</span>
                  <span>
                    {calculatedTotals.callbacks.length} | <b>{(calculatedTotals.callbacks.length / techList.length).toFixed(1)}</b>
                  </span>
                </Col>
                <Col sm={4} className="d-flex justify-content-between">
                  <span>Average Rating</span>
                  <span>
                    <b>{calculatedTotals.avgRating.toFixed(1) || "None Rated"}</b> / 5
                  </span>
                </Col>
              </Row>
              <Row>
                <Col sm={4} className="d-flex justify-content-between">
                  <span>Average Punches Completed</span>
                  <span>
                    {calculatedTotals.totalPunches || "0"} | <b>{(calculatedTotals.totalPunches / techList.length).toFixed(1)}</b>
                  </span>
                </Col>
              </Row>
            </Card>
          </Col>
        </Row>
      </Collapse>
      <hr/>
      <Row className="mt-1 d-flex justify-content-start">
        {detailedTechs.length >= 1 && detailed.map(t => {
          const techProperties = properties.filter(p => t.properties.includes(p.id));
          return <Col key={t.id} sm={4}>
            <Card body>
              <div className="text-center">
                {avatarToDisplay(t)}
              </div>
              <CardTitle className="text-center mt-2"><b>{t.name}</b></CardTitle>
              <CardSubtitle className="text-center">
                {techProperties.map((p, i) => {
                  return <span key={p.id}>{p.name}{i !== (techProperties.length - 1) ? ", " : ""}</span>
                })}
              </CardSubtitle>
              <hr/>
              {this.showTechDetails(t)}
            </Card>
          </Col>
        })}
      </Row>
      </>
  }
}

export default TechChart;
