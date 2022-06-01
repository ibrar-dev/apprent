import React from "react";
import {Modal, ModalHeader, ModalFooter, ModalBody, Button, Row, Col} from "reactstrap";
import Select from "../../../components/select";
import DatePicker from "../../../components/datePicker";
import actions from "../actions";

class AddUnitModal extends React.Component {
  state = {};

  save() {
    actions.createCard(this.state).then(this.props.toggle);
  }

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  render() {
    const {unit_id, move_out_date, move_in_date, deadline} = this.state;
    const {toggle, units} = this.props;
    const change = this.change.bind(this);
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>Add Unit</ModalHeader>
      <ModalBody>
        <Row>
          <Col>
            <div className="mb-2">Unit</div>
            <Select value={unit_id} name="unit_id" onChange={change} options={units.map(unit => {
              return {label: `${unit.property} ${unit.number}`, value: unit.id}
            })}/>
          </Col>
        </Row>
        <Row>
          <Col>
            <div className="my-2">Move Out Date</div>
            <DatePicker name="move_out_date" value={move_out_date} onChange={change}/>
          </Col>
          <Col>
            <div className="my-2">Move In Date</div>
            <DatePicker clearable name="move_in_date" value={move_in_date} onChange={change}/>
          </Col>
        </Row>
        <Row>
          <Col>
            <div className="my-2">Deadline</div>
            <DatePicker name="deadline" value={deadline} onChange={change}/>
          </Col>
          <Col/>
        </Row>
      </ModalBody>
      <ModalFooter>
        <Button className="mr-2" color="danger" onClick={toggle}>
          Cancel
        </Button>
        <Button disabled={!unit_id || !move_out_date} color="success" onClick={this.save.bind(this)}>
          Add Unit
        </Button>
      </ModalFooter>
    </Modal>;
  }
}

export default AddUnitModal;
