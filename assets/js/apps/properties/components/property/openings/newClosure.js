import React, {Component, Fragment} from 'react';
import {Row, Col, Card, CardBody, Input, Tooltip, Button} from 'reactstrap';
import moment from 'moment';
import Select from '../../../../../components/select';
import DatePicker from '../../../../../components/datePicker';
import FancyCheck from '../../../../../components/fancyCheck';
import snackbar from '../../../../../components/snackbar';
import canEdit from '../../../../../components/canEdit';
import {RingLoader} from "react-spinners";
import actions from '../../../actions';
import times from './times';
import isInclusivelyBeforeDay from "react-dates/lib/utils/isInclusivelyBeforeDay";

class NewClosure extends Component {
  state = {
    reason: '',
    full_day: false
  }

  change({target: {name, value}}) {
    this.setState({...this.state, [name]: value}, () => this.checkForAffectedShowings(name))
  }

  toggleFullDay() {
    this.setState({...this.state, full_day: !this.state.full_day})
  }

  checkForAffectedShowings(name) {
    const {date, start_time, end_time} = this.state;
    const {property} = this.props;
    if (name === "date") {
      const formatted = moment(date).format("YYYY-MM-DD");
      this.setState({fetching: true})
      actions.fetchAffectedShowings(property.id, formatted).then(r => {
        this.setState({fetching: false, affected: r.data})
      }).catch(() => this.setState({fetching: false}))
    }
  }

  toggleTooltip() {
    this.setState({...this.state, tooltip: !this.state.tooltip})
  }

  checkIfWillBeCancelled(time) {
    const {start_time, end_time, full_day} = this.state;
    if (full_day) return true;
    if ((start_time && start_time === time) || (start_time && end_time && (time >= start_time && time < end_time))) return true;
    return false
  }

  save() {
    const {reason, full_day, start_time, end_time, date} = this.state;
    const {property} = this.props;
    let new_start_time = full_day ? 0 : start_time;
    let new_end_time = full_day ? 1400 : end_time;
    const closure = {reason: reason, date: date, start_time: new_start_time, end_time: new_end_time, property_id: property.id}
    actions.saveClosure(closure);
  }

  saveForAllProperties() {
    const {date, reason, start_time, end_time, full_day} = this.state;
    if (reason.length > 1 && date && full_day) {
      actions.saveClosureAll({date: date, reason: reason, start_time: 0, end_time: 1400})
    } else if(reason.length > 1 && date && start_time < end_time) {
      actions.saveClosureAll({date: date, reason: reason, start_time: start_time, end_time: end_time})
    } else (
      snackbar({
        message: "Please fix incorrect options",
        args: {type: "error"}
      })
    )
  }

  clearForm() {
    this.setState({full_day: false, start_time: null, end_time: null, date: null, reason: ''})
  }

  render() {
    const {reason, start_time, end_time, date, full_day, fetching, affected, tooltip} = this.state;
    return <Fragment>
      <Row>
        <Col sm={6}>
          <Row>
            <Col className="d-flex justify-content-between">
              <div className="labeled-box w-100">
                <Input name="reason" value={reason} onChange={this.change.bind(this)} />
                <div className="labeled-box-label">Reason for closing</div>
              </div>
            </Col>
          </Row>
          <Row className="mt-2">
            <Col className="d-flex justify-content-between">
              <div className="labeled-box w-50">
                <DatePicker value={date} name="date" onChange={this.change.bind(this)} isOutsideRange={day => isInclusivelyBeforeDay(day, moment().subtract(1, 'days'))} />
                <div className="labeled-box-label">Start Time</div>
              </div>
              <div className="d-flex flex-content-end">
                <span className="mr-2">Closed Entire Day</span>
                <FancyCheck checked={full_day} value={full_day} onChange={this.toggleFullDay.bind(this)} />
              </div>
            </Col>
          </Row>
          {!full_day && <Fragment>
            <Row className="mt-2">
              <Col className="d-flex justify-content-between">
                <div className="labeled-box w-100">
                  <Select placeholder="Start Time"
                          value={start_time}
                          name="start_time"
                          disabled={full_day}
                          onChange={this.change.bind(this)}
                          options={times.map(t => {
                            return {value: t.value, label: t.label}
                          })} />
                  <div className="labeled-box-label">Start Time</div>
                </div>
              </Col>
            </Row>
            <Row className="mt-2">
              <Col className="d-flex justify-content-between">
                <div className="labeled-box w-100">
                  <Select placeholder="End Time"
                          value={end_time}
                          name="end_time"
                          disabled={full_day}
                          onChange={this.change.bind(this)}
                          options={times.map(t => {
                            return {value: t.value, label: t.label}
                          })} />
                  <div className="labeled-box-label">End Time</div>
                </div>
              </Col>
            </Row>
          </Fragment>}
        </Col>
        <Col sm={6}>
          <Card>
            <CardBody>
              {date && fetching && <RingLoader size={60} color="#5DBD77" />}
              {date && !fetching && affected && <Fragment>
                <div className="d-flex justify-content-between">
                  <span>Affected Showings</span>
                  <i id="info-tooltippy" className="fas fa-lg fa-question-circle" />
                </div>
                <hr/>
                {affected.map(a => {
                  const affected = this.checkIfWillBeCancelled(a.start_time)
                  return <div key={a.id} className={`d-flex justify-content-between ${affected ? 'text-danger' : ''}`} style={{textDecoration: affected ? 'line-through' : 'none'}}>
                    <span>{a.name}</span>
                    <span>
                      {moment().startOf('day').add(a.start_time, 'm').format("h:mm A")}
                    </span>
                  </div>
                })}
                <Tooltip target="info-tooltippy" isOpen={tooltip} toggle={this.toggleTooltip.bind(this)}>
                  The prospects with a line through them will automatically be cancelled and the prospect notified.
                </Tooltip>
              </Fragment>}
            </CardBody>
          </Card>
        </Col>
      </Row>
      <Row className="mt-2">
        <Col>
          <Button className="w-25" outline color="warning" onClick={this.clearForm.bind(this)}>Clear Form</Button>
          <Button className="w-75" outline color="success" onClick={this.save.bind(this)}>Save</Button>
        </Col>
      </Row>
      {canEdit(["Super Admin"]) && <Row className="mt-2">
        <Col>
          <Button onClick={this.saveForAllProperties.bind(this)} block outline color="info">Save for All Properties</Button>
        </Col>
      </Row>}
    </Fragment>
  }
}

export default NewClosure;