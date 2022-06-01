import React from 'react';
import {Modal, ModalHeader, ModalBody, ModalFooter, Input, Button} from 'reactstrap';
import actions from '../actions';

class NewDevice extends React.Component {
  state = {};

  change({target: {name, value}}) {
    this.setState({...this.state, [name]: value});
  }

  save() {
    actions.createDevice(this.state).then(this.props.toggle);
  }

  render() {
    const {name} = this.state;
    const {toggle} = this.props;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>
        New Device
      </ModalHeader>
      <ModalBody className="text-center">
        <Input value={name || ''}
               name="name"
               placeholder="Enter Device Name"
               onChange={this.change.bind(this)}/>
      </ModalBody>
      <ModalFooter>
        <Button color="success" onClick={this.save.bind(this)}>
          Create
        </Button>
      </ModalFooter>
    </Modal>
  }
}

export default NewDevice;