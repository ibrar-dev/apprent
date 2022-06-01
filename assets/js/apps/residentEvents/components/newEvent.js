import React from 'react';
import {Button, ButtonGroup, Modal, ModalBody, ModalHeader, ModalFooter, Col, Input, Row} from "reactstrap";
import moment from 'moment';
import DatePicker from "../../../components/datePicker";
import isInclusivelyBeforeDay from "react-dates/lib/utils/isInclusivelyBeforeDay";
import {validate, ValidatedInput, ValidatedSelect} from "../../../components/validationFields";
import times from "./times";
import Uploader from "../../../components/uploader";
import actions from "../actions";

class NewEvent extends React.Component {
  state = {...this.props.event, date: (this.props.event && moment(this.props.event.date))};

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  changeImage(image) {
    this.setState({image});
  }

  toggleNotify(notify) {
    this.setState({notify});
  }

  saveResidentEvent() {
    validate(this).then(() => {
      const {date, image} = this.state;
      image.upload().then(() => {
        const {property, toggle, event} = this.props;
        const {start_time, end_time, info, name, notify, location} = this.state;
        const params = {start_time, end_time, info, name, notify, location};
        params.date = date.format('YYYY-MM-DD');
        params.property_id = property.id;
        if (image.uuid) params.image = {uuid: image.uuid};
        if (event) {
          actions.updateEvent(params, property, event.id).then(toggle)
        } else {
          actions.createEvent(params, property).then(toggle);
        }
      });
    });
  }

  clear() {
    const state = this.state;
    Object.keys(state).forEach(k => state[k] = null);
    this.setState(state);
  }

  render() {
    const {toggle, event} = this.props;
    const {date, start_time, end_time, info, name, notify, location, image} = this.state;
    const change = this.change.bind(this);
    return <Modal isOpen={true} toggle={toggle} size="lg">
      <ModalHeader toggle={toggle}>New Event</ModalHeader>
      <ModalBody>
        <Row>
          <Col>
            <div className="form-group">
              <label className="d-block">
                Event Date{" "}
              </label>
              <DatePicker value={date || ''} name="date" onChange={change}
                          isOutsideRange={day => isInclusivelyBeforeDay(day, moment().subtract(1, 'days'))}/>
            </div>
            <div className="form-group">
              <label className="d-block">
                Start Time{" "}
              </label>
              <ValidatedSelect context={this}
                               validation={(start_time) => !!start_time}
                               feedback="Please select a start time"
                               placeholder='Start Time'
                               name="start_time"
                               value={start_time}
                               maxMenuHeight={210}
                               onChange={change}
                               options={times.map(t => {
                                 return {value: t.value, label: t.label}
                               })}/>
            </div>
            <div className="form-group">
              <label className="d-block">
                End Time{" "}
              </label>
              <ValidatedSelect context={this}
                               validation={() => true}
                               feedback="Please select an end time"
                               placeholder='End Time'
                               isDisabled={start_time === null}
                               value={end_time || ''}
                               name="end_time"
                               maxMenuHeight={210}
                               onChange={change}
                               options={times.filter(t => t.value > start_time).map(t => {
                                 return {value: t.value, label: t.label}
                               })}/>
            </div>
            <Uploader onChange={this.changeImage.bind(this)}/>
          </Col>
          <Col>
            <div className="form-group">
              <label className="d-block">
                Event Name{" "}
              </label>
              <ValidatedInput context={this}
                              validation={(v) => v.length > 1}
                              feedback="Name is required"
                              type="text"
                              name="name"
                              value={name || ''}
                              onChange={change}/>
            </div>
            <div className="form-group">
              <label className="d-block">
                Location{" "}
              </label>
              <Input value={location || ''} name="location" type="text" onChange={change}/>
            </div>
            <div className="form-group">
              <label className="d-block">
                Info{" "}
              </label>
              <ValidatedInput context={this}
                              validation={(v) => v.length > 1}
                              feedback="Info is required"
                              type="textarea"
                              name="info"
                              value={info || ''}
                              onChange={this.change.bind(this)} rows={4}/>
            </div>
            <div className="form-group d-flex justify-content-between align-items-center">
              <label className="m-0">
                Notify All Current Residents Of This Event{" "}
              </label>
              <ButtonGroup>
                <Button onClick={this.toggleNotify.bind(this, true)} outline active={notify}
                        color="success">Yes</Button>
                <Button onClick={this.toggleNotify.bind(this, false)} outline active={!notify}
                        color="warning">No</Button>
              </ButtonGroup>
            </div>
          </Col>
        </Row>
      </ModalBody>
      <ModalFooter>
        <Button disabled={date === null} onClick={this.saveResidentEvent.bind(this)} block outline color="success">
          {event ? 'Update' : 'Save'} Event
        </Button>
        <Button onClick={this.clear.bind(this)} className="ml-3 mt-0" block outline color="warning">Clear</Button>
      </ModalFooter>
    </Modal>
  }
}

export default NewEvent;