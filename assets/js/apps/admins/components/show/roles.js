import React from "react";
import {connect} from "react-redux";
import {withRouter} from "react-router-dom";
import {Row, Col, Label} from "reactstrap";
import actions from "../../actions";
import Checkbox from "../../../../components/fancyCheck";

class Roles extends React.Component {
  constructor(props) {
    super(props);
    this.imgRef = React.createRef();
    this.state = {
      selectedRoles: [],
    };
  }

  static getDerivedStateFromProps(props, state) {
    const {selectedRoles} = state;
    const {activeAdmin: {roles}} = props;
    if (roles !== selectedRoles) return {selectedRoles: roles};
    return null;
  }

  changeRole = (role) => {
    const {activeAdmin: {roles, id}} = this.props;
    if (roles.includes(role)) {
      roles.splice(roles.indexOf(role), 1);
    } else {
      roles.push(role)
    }
    actions.updateAdmin({id, roles});
  }

  render() {
    const {activeAdmin} = this.props;
    if (Object.keys(activeAdmin).length === 0) return null;
    const {selectedRoles} = this.state;
    return (
      <div style={{padding: 30, paddingLeft: 30, paddingRight: 30}}>
        <h4 style={{color: "#97a4af"}}>Roles</h4>
        <Row className="d-flex justify-content-around flex-wrap">
          <Label check style={{marginBottom: 10}}>
            <Checkbox
              checked={selectedRoles && selectedRoles.includes("Super Admin")}
              inline
              style={{marginBottom: -4}}
              onChange={e => this.changeRole("Super Admin", e)}
              color='primary'
            />
            {" "}
            Super Admin
          </Label>
          <Label check style={{marginBottom: 10}}>
            <Checkbox
              checked={selectedRoles && selectedRoles.includes("Admin")}
              inline
              style={{marginBottom: -4}}
              onChange={() => this.changeRole("Admin")}
              color='primary'
            />
            {" "}
            Admin
          </Label>
          <Label check style={{marginBottom: 10}}>
            <Checkbox
              checked={selectedRoles && selectedRoles.includes("Accountant")}
              inline
              style={{marginBottom: -4}}
              onChange={() => this.changeRole("Accountant")}
              color='primary'/>
            {" "}Accountant
          </Label>
          <Label check style={{marginBottom: 10}}>
            <Checkbox
              checked={selectedRoles && selectedRoles.includes("Agent")}
              inline
              style={{marginBottom: -4}}
              onChange={() => this.changeRole("Agent")}
              color='primary'/>
            {" "}Agent
          </Label>
          <Label check style={{marginBottom: 10}}>
            <Checkbox
              checked={selectedRoles && selectedRoles.includes("Regional")}
              inline
              style={{marginBottom: -4}}
              onChange={() => this.changeRole("Regional")}
              color='primary'/>
            {" "}Regional
          </Label>
          <Label check style={{marginBottom: 10}}>
            <Checkbox
              checked={selectedRoles && selectedRoles.includes("Tech")}
              inline
              style={{marginBottom: -4}}
              onChange={() => this.changeRole("Tech")}
              color='primary'/>
            {" "}Tech
          </Label>
          <Label check style={{marginBottom: 10}}>
            <Checkbox
              checked={selectedRoles && selectedRoles.includes("Property")}
              inline
              style={{marginBottom: -4}}
              onChange={() => this.changeRole("Property")}
              color='primary'/>
            {" "}Property
          </Label>
        </Row>
      </div>
    )
  }
}

export default withRouter(connect(({activeAdmin}) => ({activeAdmin}))(Roles));
