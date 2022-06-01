import React from 'react';
import {Modal, ModalHeader, ModalBody, ModalFooter, Button} from 'reactstrap';
import {ValidatedInput, validate} from '../../../components/validationFields';
import actions from "../actions";
import {withRouter} from "react-router-dom";

class NewUnit extends React.Component {
  state = {};

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  createUnit() {
    validate(this).then(() => {
      const {toggle, property} = this.props;
      actions.createUnit({...this.state, property_id: property.id}).then((r) => {
        toggle();
      });
    });
  }

  render() {
    const {toggle, property} = this.props;
    const {number} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        New Unit: {property.name}
      </ModalHeader>
      <ModalBody>
        <div className="labeled-box">
          <ValidatedInput
            context={this}
            validation={(v) => v && v.length >= 1}
            feedback="Number is required"
            name="number"
            onChange={this.change.bind(this)}
            value={number || ''}
          />
          <div className="labeled-box-label">Unit Number</div>
        </div>
      </ModalBody>
      <ModalFooter>
        <Button color="success" onClick={this.createUnit.bind(this)}>
          Next
        </Button>
      </ModalFooter>
    </Modal>
  }
}

export default withRouter(NewUnit);
