import React from 'react';
import {InputGroupAddon, InputGroup, FormFeedback} from 'reactstrap';
import actions from "../actions";

class Password extends React.Component {
  state = {password: ''};

  changePassword(e) {
    const password = e.target.value;
    this.setState({...this.state, valid: (password.length > 7), password});
  }

  saveNewPW() {
    const id = this.props.adminId;
    const {password} = this.state;
    actions.updateAdmin({id, password}).then(this.props.toggleForm());
  }

  render() {
    const {valid, password} = this.state;
    const {toggleForm} = this.props;
    return (
      <>
        <InputGroup className="w-75 d-flex">
          <input className={`form-control is-${!valid && 'in'}valid`}
                value={password}
                placeholder="New Password"
                onChange={this.changePassword.bind(this)}/>
          <InputGroupAddon addonType="append">
            <a onClick={this.saveNewPW.bind(this)}
              className={`m-0 btn btn-outline-${valid ? 'success' : 'danger disabled'}`}>
              <i className="fas fa-check"/>
            </a>
          </InputGroupAddon>
          <InputGroupAddon addonType="append">
            <a onClick={toggleForm} className={`m-0 btn btn-outline-secondary`}>
              <i className="fas fa-times text-danger"/>
            </a>
          </InputGroupAddon>
        </InputGroup>
        <FormFeedback className={!valid ? "d-block" : ''}>Password must be at least 8 characters.</FormFeedback>
      </>
    )
  }
}

export default Password;