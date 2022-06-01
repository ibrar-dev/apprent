import React, {Component} from "react";
import {Modal, ModalHeader, ModalBody, ModalFooter, Button, Input} from "reactstrap";
import confirmation from "../../../../../components/confirmationModal";
import actions from "../../../actions";

class CaptureLease extends Component {
  constructor(props) {
    super(props);
    this.state = {
      cannotSubmit: true,
      signature_id: "",
      bluemoon_id: "",
    };

    this.change = this.change.bind(this);
    this.submit = this.submit.bind(this);
  }

  change({target: {name, value}}) {
    let new_val = value;
    if (name === "bluemoon_id") {
      new_val = this.parseForID(value);
    }
    this.setState({[name]: new_val});
    this.setState({cannotSubmit: this.cannotSubmit()})
  }

  parseForID(value) {
    const regex = RegExp("\A?record=[^&]+&*");
    let string = regex.exec(value);
    if (string && string[0].includes("record=")) {
      return string[0].replace("record=", "").replace("&", "")
    } else {
      return value
    }
  }

  submit() {
    confirmation("Proceed with this BlueMoon ID?").then(() => {
      const {bluemoon_id, signature_id} = this.state;
      const {leaseId} = this.props
      actions.attachBlueMoonLease({
        lease_id: leaseId,
        bluemoon_id,
        signature_id
      }).then(this.props.toggle);
    });
  }

  // Check to ensure that we have bluemoon id and signature id, and that both have real values
  cannotSubmit() {
    const {bluemoon_id, signature_id} = this.state;
    return !(
      bluemoon_id &&
      bluemoon_id.length > 0 &&
      signature_id &&
      signature_id.length > 0
    );
  }

  render() {
    const {toggle} = this.props;
    const {bluemoon_id, signature_id, cannotSubmit} = this.state;

    return (
      <Modal isOpen={true} toggle={toggle}>
        <ModalHeader>Attach BlueMoon Lease</ModalHeader>
        <ModalBody>
          <div>Enter the BlueMoon ID of this resident's lease</div>
          <div className="labeled-box mt-3">
            <Input
              name="bluemoon_id"
              value={bluemoon_id}
              onChange={this.change}
            />
            <div className="labeled-box-label">BlueMoon ID</div>
          </div>
          <div className="labeled-box mt-3">
            <Input
              name="signature_id"
              value={signature_id}
              onChange={this.change}
            />
            <div className="labeled-box-label">Signature ID</div>
          </div>
        </ModalBody>
        <ModalFooter>
          <Button
            color="success"
            onClick={this.submit}
            disabled={cannotSubmit}
          >
            Get Lease
          </Button>
        </ModalFooter>
      </Modal>
    );
  }
}

export default CaptureLease;
