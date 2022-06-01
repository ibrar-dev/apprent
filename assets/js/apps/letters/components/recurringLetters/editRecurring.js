import React, {Component} from 'react';
import {Modal, ModalHeader, ModalBody, ModalFooter, Input, Row, Col, ButtonGroup, Button} from 'reactstrap';
import TimePicker from '../../../../components/datePicker/timepicker';
import ScheduleField from "./scheduleField";
import DatePicker from "../../../../components/datePicker";
import Select from '../../../../components/select';
import actions from '../../actions';
import {connect} from "react-redux";

const types = [{value: 'd', label: 'Daily'}, {value: 'w', label: 'Weekly'}, {value: 'm', label: 'Monthly'}];
const typeKey = {d: 'day', w: 'wday', m: 'month'};

class EditRecurring extends Component {
  state = {type: "d"}

  constructor(props) {
    super(props);
    this.state = {
      ...props.selectedLetter,
      type: "d"
    }
  }


  setSchedule(field, value) {
    this.setState({schedule: {...this.state.schedule, [field]: value}});
  }

  change({target: {name, value}}) {
    this.setState({...this.state, [name]: value})
  }

  changeTime({hour: hour, minute: minute}) {
    this.setState({schedule: {...this.state.schedule, hour: [hour], minute: [minute]}});
  }

  changeFilter({target: {name, value}}) {
    this.setState({resident_params: {...this.state.resident_params, [name]: value}})
  }

  changeCheckbox({target: {name}}) {
    const {resident_params} = this.state;
    resident_params[name] = !resident_params[name];
    this.setState({...this.state, resident_params: resident_params})
  }

  changeVisibleNotify({target: {name}}) {
    const {notify} = this.state;
    if (name === 'notify' && !notify) return this.setState({...this.state, notify: true, visible: true});
    if (name === 'visible' && notify) return this.setState({
      ...this.state,
      notify: false,
      visible: !this.state.visible
    });
    this.setState({...this.state, [name]: !this.state[name]})
  }

  adminsToDisplay() {
    const {admins, property} = this.props;
    return admins.filter(a => a.properties.includes(property.id))
  }

  saveRecurringLetter() {
    let recurring_letter = this.state;
    const {property} = this.props;
    recurring_letter.property_id = property.id;
    actions.updateRecurringLetter(recurring_letter.id, recurring_letter);
  }

  render() {
    const {toggle, letters} = this.props;
    const {name, visible, notify, resident_params, schedule, type, admin_id, letter_template_id} = this.state;
    const field = typeKey[type];
    console.log(this.state);
    return <Modal isOpen={true} size="lg" toggle={toggle}>
      <ModalHeader toggle={toggle} className="d-flex justify-content-between">
        <Input className="flex-fill" placeholder="Name" name="name" value={name} onChange={this.change.bind(this)}/>
      </ModalHeader>
      <ModalBody>
        <Row>
          <Col xs={2}>
            <ButtonGroup outline vertical>
              <Button active={type === "d"} outline color="info"
                      onClick={this.change.bind(this, {target: {name: "type", value: "d"}})}>Monthly</Button>
              <Button active={type === "w"} outline color="info"
                      onClick={this.change.bind(this, {target: {name: "type", value: "w"}})}>Weekly</Button>
              {/*<Button active={type === "m"} outline color="info" onClick={this.change.bind(this, {target: {name: "type", value: "m"}})}>Certain Months</Button>*/}
            </ButtonGroup>
          </Col>
          <Col>
            {field && <ScheduleField field={field} value={schedule[field]} setSchedule={this.setSchedule.bind(this)}/>}
          </Col>
        </Row>
        <Row className="mt-2">
          <Col>
            <div className="labeled-box">
              <TimePicker onChange={this.changeTime.bind(this)}/>
              <div className="labeled-box-label">Time</div>
            </div>
          </Col>
        </Row>
        <hr/>
        <Row className="mt-1">
          <Col>
            <Row>
              <Col>
                <div className="d-flex justify-content-between">
                  <div className="labeled-box flex-fill">
                    <Input type="number" name="min_balance" value={resident_params.min_balance || ''}
                           onChange={this.changeFilter.bind(this)}/>
                    <div className="labeled-box-label">Min Balance Amount</div>
                  </div>
                  <div className="labeled-box flex-fill ml-1">
                    <Input type="text" name="resident_name" value={resident_params.resident_name || ''}
                           onChange={this.changeFilter.bind(this)}/>
                    <div className="labeled-box-label">Resident Name</div>
                  </div>
                  <div className="labeled-box flex-fill ml-1">
                    <Select value={letter_template_id}
                            options={letters.map(l => {
                              return {label: l.name, value: l.id}
                            })}
                            name="letter_template_id"
                            onChange={this.change.bind(this)} />
                    <div className="labeled-box-label">Letter Template</div>
                  </div>
                </div>
              </Col>
            </Row>
            <Row className="mt-2">
              <Col className="d-flex justify-content-between">
                <div className="labeled-box flex-fill">
                  <DatePicker clearable value={resident_params.lease_end_date} name="lease_end_date"
                              onChange={this.changeFilter.bind(this)}/>
                  <div className="labeled-box-label">Leases Ending By</div>
                </div>
                <div className="labeled-box flex-fill ml-1">
                  <Select value={admin_id}
                          options={this.adminsToDisplay().map(a => {
                            return {label: a.name, value: a.id}
                          })}
                          onChange={this.change.bind(this)}
                          placeholder="Employee"
                          name="admin_id"/>
                  <div className="labeled-box-label">Admin</div>
                </div>
              </Col>
            </Row>
            <Row>
              <Col>
                <table className="table table-borderless">
                  <tbody>
                  <tr>
                    <td>Current</td>
                    <td><Input type="checkbox" name="current" checked={resident_params.current}
                               onChange={this.changeCheckbox.bind(this)}/></td>
                  </tr>
                  <tr>
                    <td>Past</td>
                    <td><Input type="checkbox" name="past" checked={resident_params.past}
                               onChange={this.changeCheckbox.bind(this)}/></td>
                  </tr>
                  <tr>
                    <td>Future</td>
                    <td>
                      <Input type="checkbox" name="future" checked={resident_params.future}
                             onChange={this.changeCheckbox.bind(this)}/>
                    </td>
                  </tr>
                  <tr>
                    <td>Visible</td>
                    <td>
                      <Input type="checkbox" name="visible" checked={visible}
                             onChange={this.changeVisibleNotify.bind(this)}/>
                    </td>
                  </tr>
                  <tr>
                    <td>Notify</td>
                    <td>
                      <Input type="checkbox" name="notify" checked={notify}
                             onChange={this.changeVisibleNotify.bind(this)}/>
                    </td>
                  </tr>
                  </tbody>
                </table>
              </Col>
            </Row>
          </Col>
        </Row>
      </ModalBody>
      <ModalFooter>
        <Button outline color="success" onClick={this.saveRecurringLetter.bind(this)}>Save</Button>
      </ModalFooter>
    </Modal>
  }
}

export default connect(({admins, property, letters}) => {
  return {admins, property, letters}
})(EditRecurring);