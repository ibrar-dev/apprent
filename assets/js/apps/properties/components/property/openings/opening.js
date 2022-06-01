import React from 'react';
import {Modal, ModalHeader, ModalBody, Button, Input, Row, Col} from 'reactstrap';
import TimeInput from './timeInput';
import actions from '../../../actions';

const weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

class Opening extends React.Component {
  state = {opening: this.props.opening, periods: {end_time: 'PM', start_time: 'AM'}};

  change({target: {name, value}}) {
    this.setState({...this.state, opening: {...this.state.opening, [name]: value}});
  }

  save() {
    const {opening} = this.state;
    const action = opening.id ? 'updateOpening' : 'createOpening';
    actions[action](opening).then(this.props.toggle);
  }

  deleteOpening() {
    actions.deleteOpening(this.state.opening).then(this.props.toggle);
  }

  render() {
    const {toggle} = this.props;
    const {opening} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        {weekdays[opening.wday]}
      </ModalHeader>
      <ModalBody>
        <TimeInput label="Start Time"
                   name="start_time"
                   time={opening.start_time}
                   onChange={this.change.bind(this)}/>
        <TimeInput label="End Time"
                   name="end_time"
                   time={opening.end_time}
                   onChange={this.change.bind(this)}/>
        <div className="d-flex justify-content-center mt-3">
          <label className="d-flex w-50 align-items-center" style={{whiteSpace: 'nowrap'}}>
            Available Slots
            <Input value={opening.showing_slots}
                   onChange={this.change.bind(this)}
                   className="ml-3"
                   type="number"
                   name="showing_slots"/>
          </label>
        </div>
        <Row className="mt-3">
          <Col sm={1}/>
          <Col>
            <Button onClick={this.save.bind(this)} block color="success">
              Save
            </Button>
          </Col>
          {opening.id && <Col>
            <Button onClick={this.deleteOpening.bind(this)} block color="danger">
              Delete
            </Button>
          </Col>}
          <Col sm={1}/>
        </Row>
      </ModalBody>
      <
      /Modal>;
      }
      }

      export default Opening;