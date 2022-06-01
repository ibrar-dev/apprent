import {Button, Input, Modal, ModalBody, ModalFooter, ModalHeader} from "reactstrap";
import React, {Component} from "react";
import confirmation from "../../../components/confirmationModal";
import actions from "../actions";

class AttachBlueMoon extends Component{
    state = {};

    change({target: {name, value}}) {
        let new_val = value;
        if (name === "bluemoon_id") {
            new_val = this.parseForID(value);
        }
        this.setState({[name]: new_val});
    }

    parseForID(value) {
        const regex = RegExp('\A?record=[^&]+&*');
        let string = regex.exec(value);
        if (string && string[0].includes('record=')) {
            return string[0].replace('record=', '').replace('&', '')
        } else {
            return value
        }
    }

    submit() {
        confirmation('Proceed with this BlueMoon ID?').then(() => {
            const {application} = this.props;
            const {bluemoon_id, signature_id} = this.state;
            actions.bypassApproveApplication(application.id, {bluemoon_id, signature_id}).then(this.props.toggle);
        });
    }

    render() {
        const {toggle} = this.props;
        const {bluemoon_id, signature_id} = this.state;
        return <Modal isOpen={true} toggle={toggle}>
            <ModalHeader>Attach BlueMoon Lease</ModalHeader>
            <ModalBody>
                <div>Enter the BlueMoon ID of this resident's lease</div>
                <div className="labeled-box mt-3">
                    <Input name="bluemoon_id" value={bluemoon_id || ''} onChange={this.change.bind(this)}/>
                    <div className="labeled-box-label">BlueMoon ID</div>
                </div>
                <div className="labeled-box mt-3">
                    <Input name="signature_id" value={signature_id || ''} onChange={this.change.bind(this)}/>
                    <div className="labeled-box-label">Signature ID</div>
                </div>
            </ModalBody>
            <ModalFooter>
                <Button color="success" onClick={this.submit.bind(this)}>
                    Create Lease
                </Button>
            </ModalFooter>
        </Modal>;
    }
}

export default AttachBlueMoon;