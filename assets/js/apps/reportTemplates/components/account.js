import React from 'react';
import {Button, Input, InputGroup, InputGroupAddon} from "reactstrap";
import Select from "../../../components/select";

class Account extends React.Component {
  state = {};

  toggleEdit() {
    this.setState({...this.state, editMode: !this.state.editMode});
  }

  render() {
    const {account, accountOpts, deleteAccount, changeAccount, moveUp, moveDown} = this.props;
    const {editMode} = this.state;
    const options = [...accountOpts];
    if (account) options.unshift({id: account.id, label: account.name});
    return (account && !editMode) ? <div>
      <InputGroup className="d-inline-flex w-75 mr-4">
        <Input value={`${account.num} - ${account.name}`} readOnly className="bg-white"/>
        <InputGroupAddon addonType="append">
          <Button onClick={this.toggleEdit.bind(this)} color="outline-info">
            <i className="fas fa-edit"/>
          </Button>
          <Button onClick={deleteAccount} color="outline-danger">
            <i className="fas fa-times"/>
          </Button>
          <Button onClick={moveUp} color="outline-secondary">
            <i className="fas fa-arrow-circle-up"/>
          </Button>
          <Button onClick={moveDown} color="outline-secondary">
            <i className="fas fa-arrow-circle-down"/>
          </Button>
        </InputGroupAddon>
      </InputGroup>
    </div> : <Select style={{flex: 1}} onChange={changeAccount} name="id" options={options} menuIsOpen/>;
  }
}

export default Account;