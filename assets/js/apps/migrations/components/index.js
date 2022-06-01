import React from 'react';
import {connect} from 'react-redux';
import {Button, Modal, ModalHeader, ModalBody, Form, FormGroup, Label, Input} from 'reactstrap';
import Migration from './migration';
import Pagination from '../../../components/pagination';
import actions from '../actions';

const headers = [
  {label: '', min: true},
  {label: "Module"},
  {label: "Function"},
  {label: "Arguments"}
];

class Migrations extends React.Component {
  state = {newMigration: {module: '', 'function': '', arguments: []}};

  toggleModal() {
    this.setState({modalOpen: !this.state.modalOpen});
  }

  changeNewMigration({target: {name, value}}) {
    this.setState({newMigration: {...this.state.newMigration, [name]: value}});
  }

  createMigration() {
    actions.createMigration(this.state.newMigration).then(this.toggleModal.bind(this));
  }

  render() {
    const {migrations} = this.props;
    const {modalOpen, newMigration} = this.state;
    return <div>
      <h3>WARNING: This page is for technical staff only!</h3>
      <Pagination
        component={Migration}
        collection={migrations}
        title={<div>Migrations
          <Button color="success" onClick={this.toggleModal.bind(this)} className="ml-4">
            Create New
          </Button>
        </div>}
        headers={headers}
        field="migration"
      />
      <Modal isOpen={modalOpen} toggle={this.toggleModal.bind(this)}>
        <ModalHeader>
          New Migration
        </ModalHeader>
        <ModalBody>
          <Form>
            <FormGroup>
              <Label for="module">Module</Label>
              <Input onChange={this.changeNewMigration.bind(this)} name="module" value={newMigration.module}/>
            </FormGroup>
            <FormGroup>
              <Label for="module">Function</Label>
              <Input onChange={this.changeNewMigration.bind(this)} name="function" value={newMigration.function}/>
            </FormGroup>
          </Form>
          <Button color="success" onClick={this.createMigration.bind(this)}>
            Create
          </Button>
        </ModalBody>
      </Modal>
    </div>
  }
}

export default connect(({migrations}) => {
  return {migrations}
})(Migrations);