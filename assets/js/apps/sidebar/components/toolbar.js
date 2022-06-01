import React from "react";
import {connect} from "react-redux";
import {ButtonGroup, ButtonToolbar} from "reactstrap";
import {permissions} from "../links";
import ToolbarButton from "./toolbarButton";

const iconKey = {
  "Super Admin": "fas fa-universal-access",
  Agent: "fas fa-user-tie",
  Admin: "fas fa-warehouse",
  Accountant: "fas fa-hand-holding-usd",
  Tech: "fas fa-robot",
  Property: "fas fa-robot",
};

const Toolbar = ({role}) => (
  <ButtonToolbar>
    <ButtonGroup className="w-100">
      {
        permissions.map((p) => (
          <ToolbarButton
            key={p}
            roleName={p}
            selected={role === p}
            icon={iconKey[p]}
          />
        ))
      }
    </ButtonGroup>
  </ButtonToolbar>
);

export default connect(({role}) => ({role}))(Toolbar);
