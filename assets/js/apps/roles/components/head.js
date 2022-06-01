import React from 'react';
import {Input, Button} from 'antd';
import NewRoleModal from './newRoleModal';

class Head extends React.Component {
  state = {};

  changeSearchTerm({target: {name, value}}) {
    this.setState({[name]: value})
  }

  toggleNewRoleModal() {
    this.setState({createRoleModalOpen: !this.state.createRoleModalOpen})
  }

  render() {
    const {searchTerm, createRoleModalOpen} = this.state;
    return <div className="d-flex justify-content-end">
      <Input placeholder="Search"
             className="w-auto"
             value={searchTerm}
             name="searchTerm"
             onChange={this.changeSearchTerm.bind(this)}/>
      <Button className="ml-2" color="success" onClick={this.toggleNewRoleModal.bind(this)}>
        New Role
      </Button>
      {createRoleModalOpen && <NewRoleModal toggle={this.toggleNewRoleModal.bind(this)}/>}
    </div>;
  }
}

export default Head;