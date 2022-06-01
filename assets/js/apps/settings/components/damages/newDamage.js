import React from 'react';
import {connect} from 'react-redux';
import {Modal, ModalHeader, ModalBody, ModalFooter, Input, Button} from 'reactstrap';
import actions from '../../actions';
import Select from '../../../../components/select';

class NewDamage extends React.Component {
  state = {};

  change({target: {name, value}}) {
    this.setState({[name]: value});
  }

  save() {
    actions.createDamage(this.state).then(this.props.toggle);
  }

  render() {
    const {toggle, accounts} = this.props;
    const {name, account_id} = this.state;
    return <Modal isOpen={true} toggle={toggle}>
      <ModalHeader toggle={toggle}>New Damage</ModalHeader>
      <ModalBody>
        <div className="mb-4">
          <Select options={accounts.map(a => {
            return {label: a.name, value: a.id};
          })} value={account_id} onChange={this.change.bind(this)} name="account_id"
          />
        </div>
        <Input value={name || ''} name="name" onChange={this.change.bind(this)} placeholder="New Damage"/>
      </ModalBody>
      <ModalFooter>
        <Button color="success" onClick={this.save.bind(this)}>
          Create
        </Button>
      </ModalFooter>
    </Modal>
  }
}

export default connect(({accounts}) => {
  return {accounts};
})(NewDamage);