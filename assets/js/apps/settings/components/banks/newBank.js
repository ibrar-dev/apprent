import React from 'react';
import {Modal, ModalHeader, ModalBody, ModalFooter, Input, Button} from 'reactstrap';
import actions from '../../actions';

class NewDamage extends React.Component {
  state = {};

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  save() {
    const {name, routing} = this.state;
    actions.createBank({name, routing}).then(this.props.toggle);
  }

  render() {
    const {toggle} = this.props;
    const {name, routing} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>New Bank</ModalHeader>
      <ModalBody>
        <div className="mb-2">
          <Input value={name || ''} name="name" onChange={this.change.bind(this)} placeholder="Bank name"/>
        </div>
        <Input value={routing || ''} name="routing" onChange={this.change.bind(this)} placeholder="Routing Number"/>
      </ModalBody>
      <ModalFooter>
        <Button color="success" onClick={this.save.bind(this)}>
          Create
        </Button>
      </ModalFooter>
    </Modal>
  }
}

export default NewDamage;