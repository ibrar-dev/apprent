import React from 'react';
import {Modal, ModalHeader, ModalBody, ModalFooter, Input, Button} from 'reactstrap';
import actions from '../../actions';

class NewMoveOutReason extends React.Component {
  state = {};

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  save() {
    actions.createMoveOutReason({name: this.state.name}).then(this.props.toggle);
  }

  render() {
    const {toggle} = this.props;
    const {name} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>New Move Out Reason</ModalHeader>
      <ModalBody>
        <Input value={name || ''} name="name" onChange={this.change.bind(this)} placeholder="New Move Out Reason"/>
      </ModalBody>
      <ModalFooter>
        <Button color="success" onClick={this.save.bind(this)}>
          Create
        </Button>
      </ModalFooter>
    </Modal>
  }
}

export default NewMoveOutReason;