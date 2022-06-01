import React from "react";
import {Label, Input} from "reactstrap";
import actions from "../actions";
import Checkbox from "../../../components/fancyCheck";

class Entity extends React.Component {
  assignAdmin = () => {
    actions.assignAdmin(this.props.adminId, !this.props.checked, this.props.entity.id);
  }

  render() {
    const {name} = this.props.entity;
    return (
      <Label check>
        <Checkbox
          checked={this.props.checked}
          inline
          style={{marginBottom: -4}}
          onChange={() => this.assignAdmin()}
          color='primary'
        />
        {" "}
        {name}
      </Label>
    );
  }
}

export default Entity;
